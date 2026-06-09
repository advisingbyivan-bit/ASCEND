import { Router, Request, Response } from "express";
import Stripe from "stripe";
import { config } from "../config";
import { requireAuth } from "../middleware/auth";
import { UserModel } from "../models/User";
import { query } from "../db/connection";

const router = Router();

// Initialize Stripe — will fail gracefully if key not set
let stripe: Stripe | null = null;
if (config.stripe.secretKey) {
  stripe = new Stripe(config.stripe.secretKey, {
    apiVersion: "2025-05-28.basil",
  });
}

// ----- Price mapping -----
// Map our plan names to Stripe price IDs (set these in env vars after creating products in Stripe Dashboard)
const PRICE_MAP: Record<string, string> = {
  weekly: config.stripe.weeklyPriceId,
  monthly: config.stripe.monthlyPriceId,
};

// ----- Helper: get or create Stripe customer -----
async function getOrCreateCustomer(userId: string): Promise<string> {
  if (!stripe) throw new Error("Stripe not configured");

  const user = await UserModel.findById(userId);
  if (!user) throw new Error("User not found");

  // Return existing Stripe customer
  const existing = await query<{ stripe_customer_id: string }>(
    "SELECT stripe_customer_id FROM users WHERE id = $1",
    [userId]
  );
  if (existing.rows[0]?.stripe_customer_id) {
    return existing.rows[0].stripe_customer_id;
  }

  // Create new Stripe customer
  const customer = await stripe.customers.create({
    email: user.email || undefined,
    name: user.display_name || undefined,
    metadata: {
      ascend_user_id: userId,
    },
  });

  // Save to DB
  await query(
    "UPDATE users SET stripe_customer_id = $1 WHERE id = $2",
    [customer.id, userId]
  );

  return customer.id;
}

// ===== POST /stripe/checkout =====
// Creates a Stripe Checkout Session and returns the URL.
// Called from the iOS app — opens in Safari.
router.post("/checkout", requireAuth, async (req: Request, res: Response) => {
  try {
    if (!stripe) {
      res.status(503).json({ error: "Stripe not configured" });
      return;
    }

    const { plan } = req.body; // "weekly" or "monthly"
    const priceId = PRICE_MAP[plan];
    if (!priceId) {
      res.status(400).json({ error: "Invalid plan. Use 'weekly' or 'monthly'." });
      return;
    }

    const userId = req.userId!;
    const customerId = await getOrCreateCustomer(userId);

    // Determine trial eligibility — only monthly gets a free trial
    const trialDays = plan === "monthly" ? 3 : undefined;

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      subscription_data: trialDays
        ? { trial_period_days: trialDays }
        : undefined,
      success_url: `${config.stripe.checkoutDomain}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${config.stripe.checkoutDomain}/checkout/cancel`,
      metadata: {
        ascend_user_id: userId,
        plan,
      },
      allow_promotion_codes: true,
    });

    res.json({ url: session.url });
  } catch (err: any) {
    console.error("[Stripe] Checkout error:", err.message);
    res.status(500).json({ error: "Failed to create checkout session" });
  }
});

// ===== GET /stripe/portal =====
// Creates a Stripe Customer Portal session for managing subscriptions.
router.get("/portal", requireAuth, async (req: Request, res: Response) => {
  try {
    if (!stripe) {
      res.status(503).json({ error: "Stripe not configured" });
      return;
    }

    const userId = req.userId!;
    const result = await query<{ stripe_customer_id: string }>(
      "SELECT stripe_customer_id FROM users WHERE id = $1",
      [userId]
    );

    const customerId = result.rows[0]?.stripe_customer_id;
    if (!customerId) {
      res.status(404).json({ error: "No Stripe customer found. Subscribe first." });
      return;
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${config.stripe.checkoutDomain}/checkout/success`,
    });

    res.json({ url: session.url });
  } catch (err: any) {
    console.error("[Stripe] Portal error:", err.message);
    res.status(500).json({ error: "Failed to create portal session" });
  }
});

// ===== GET /stripe/status =====
// Check subscription status from Stripe for the authenticated user.
router.get("/status", requireAuth, async (req: Request, res: Response) => {
  try {
    const userId = req.userId!;
    const user = await UserModel.findById(userId);
    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    res.json({
      subscription_status: user.subscription_status,
      subscription_plan: user.subscription_plan,
      subscription_expiry: user.subscription_expiry,
      subscription_source: (user as any).subscription_source || "appstore",
    });
  } catch (err: any) {
    console.error("[Stripe] Status error:", err.message);
    res.status(500).json({ error: "Failed to get subscription status" });
  }
});

// ===== POST /stripe/webhook =====
// Stripe webhook endpoint. MUST use raw body for signature verification.
// This is mounted separately in index.ts with express.raw() middleware.
export async function handleStripeWebhook(req: Request, res: Response) {
  if (!stripe) {
    res.status(503).send("Stripe not configured");
    return;
  }

  const sig = req.headers["stripe-signature"] as string;
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body, // raw body
      sig,
      config.stripe.webhookSecret
    );
  } catch (err: any) {
    console.error("[Stripe Webhook] Signature verification failed:", err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle events
  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      await handleCheckoutCompleted(session);
      break;
    }
    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription;
      await handleSubscriptionUpdated(subscription);
      break;
    }
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      await handleSubscriptionDeleted(subscription);
      break;
    }
    case "invoice.payment_failed": {
      const invoice = event.data.object as Stripe.Invoice;
      await handlePaymentFailed(invoice);
      break;
    }
    default:
      // Unhandled event type — log for debugging
      console.log(`[Stripe Webhook] Unhandled event: ${event.type}`);
  }

  res.json({ received: true });
}

// ----- Webhook handlers -----

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.ascend_user_id;
  const plan = session.metadata?.plan || "weekly";

  if (!userId) {
    console.error("[Stripe] Checkout completed but no ascend_user_id in metadata");
    return;
  }

  // Get subscription details
  let expiryDate = new Date();
  if (session.subscription && stripe) {
    const sub = await stripe.subscriptions.retrieve(session.subscription as string);
    expiryDate = new Date(sub.current_period_end * 1000);
  }

  const status = session.payment_status === "paid" ? "active" : "trialing";

  await UserModel.update(userId, {
    subscription_status: status,
    subscription_plan: plan,
    subscription_expiry: expiryDate,
  });

  // Also set subscription_source to 'stripe'
  await query(
    "UPDATE users SET subscription_source = 'stripe' WHERE id = $1",
    [userId]
  );

  console.log(`[Stripe] User ${userId} subscribed to ${plan} (${status}), expires ${expiryDate.toISOString()}`);
}

async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  // Find user by Stripe customer ID
  const result = await query<{ id: string }>(
    "SELECT id FROM users WHERE stripe_customer_id = $1",
    [customerId]
  );

  if (!result.rows[0]) {
    console.warn("[Stripe] Subscription updated for unknown customer:", customerId);
    return;
  }

  const userId = result.rows[0].id;
  const status = subscription.status === "trialing" ? "trialing" :
                 subscription.status === "active" ? "active" : "expired";
  const expiryDate = new Date(subscription.current_period_end * 1000);

  // Determine plan from price ID
  const priceId = subscription.items.data[0]?.price?.id;
  const plan = priceId === config.stripe.weeklyPriceId ? "weekly" :
               priceId === config.stripe.monthlyPriceId ? "monthly" : "weekly";

  await UserModel.update(userId, {
    subscription_status: status,
    subscription_plan: plan,
    subscription_expiry: expiryDate,
  });

  console.log(`[Stripe] User ${userId} subscription updated: ${status}, ${plan}, expires ${expiryDate.toISOString()}`);
}

async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  const result = await query<{ id: string }>(
    "SELECT id FROM users WHERE stripe_customer_id = $1",
    [customerId]
  );

  if (!result.rows[0]) return;

  const userId = result.rows[0].id;

  await UserModel.update(userId, {
    subscription_status: "expired",
    subscription_plan: null,
    subscription_expiry: null,
  });

  console.log(`[Stripe] User ${userId} subscription cancelled`);
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const customerId = invoice.customer as string;

  const result = await query<{ id: string }>(
    "SELECT id FROM users WHERE stripe_customer_id = $1",
    [customerId]
  );

  if (!result.rows[0]) return;

  console.warn(`[Stripe] Payment failed for user ${result.rows[0].id}`);
  // Don't immediately expire — Stripe retries. The subscription.deleted event handles final cancellation.
}

export default router;
