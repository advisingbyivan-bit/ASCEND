import { config } from "../config";

/**
 * Structured zone diagnosis returned by Claude Vision analysis.
 */
export interface ZoneDiagnosis {
  zone_name: string;
  status: "improved" | "maintained" | "declined" | "new_baseline";
  delta: number;
  note: string;
}

export interface DiagnosisResult {
  overall_score: number;
  iris_message: string;
  zones: ZoneDiagnosis[];
}

/**
 * Encode a remote image URL or local buffer to a base64 data URL for the Anthropic API.
 */
function imageSourceFromUrl(url: string): {
  type: "image";
  source: { type: "url"; url: string };
} {
  return {
    type: "image",
    source: { type: "url", url },
  };
}

function imageSourceFromBase64(
  base64: string,
  mediaType: string
): {
  type: "image";
  source: { type: "base64"; media_type: string; data: string };
} {
  return {
    type: "image",
    source: { type: "base64", media_type: mediaType, data: base64 },
  };
}

/**
 * Build the system prompt for body scan analysis.
 */
function buildSystemPrompt(userContext: {
  gender: string;
  age: number;
  height_cm: number;
  weight_kg: number;
  goal_weight_kg: number;
  body_concerns: string;
  training_frequency: string;
  timeline: string;
}): string {
  return `You are IRIS, an advanced AI body composition analyst for the ASCEND fitness app. You analyze body scan photos to provide detailed zone-by-zone assessments of physique progress.

USER PROFILE:
- Gender: ${userContext.gender}
- Age: ${userContext.age}
- Height: ${userContext.height_cm}cm
- Current Weight: ${userContext.weight_kg}kg
- Goal Weight: ${userContext.goal_weight_kg}kg
- Body Concerns: ${userContext.body_concerns || "None specified"}
- Training Frequency: ${userContext.training_frequency}
- Timeline: ${userContext.timeline}

INSTRUCTIONS:
Analyze the provided body scan images and return a JSON response with:
1. An overall physique score from 0-100
2. A motivational message (2-3 sentences) as IRIS
3. Zone-by-zone breakdown

ZONES TO EVALUATE:
- Shoulders, Chest, Arms, Core/Abs, Back, Legs/Quads, Calves, Glutes

For each zone provide:
- status: "improved", "maintained", "declined", or "new_baseline" (use new_baseline for first scan)
- delta: numeric change estimate (-10 to +10 scale)
- note: brief observation (1-2 sentences)

RESPOND ONLY WITH VALID JSON in this exact format:
{
  "overall_score": <number>,
  "iris_message": "<string>",
  "zones": [
    {
      "zone_name": "<string>",
      "status": "<string>",
      "delta": <number>,
      "note": "<string>"
    }
  ]
}`;
}

/**
 * Call the Anthropic Messages API with Vision to analyze body scan images.
 */
export async function analyzeBodyScan(
  imageUrls: { front?: string; side?: string; back?: string },
  userContext: {
    gender: string;
    age: number;
    height_cm: number;
    weight_kg: number;
    goal_weight_kg: number;
    body_concerns: string;
    training_frequency: string;
    timeline: string;
  },
  previousScanData?: {
    overall_score: number;
    zones: Array<{ zone_name: string; status: string; delta: number; note: string }>;
  }
): Promise<DiagnosisResult> {
  if (!config.anthropicApiKey) {
    throw new Error("ANTHROPIC_API_KEY is not configured");
  }

  // Build image content blocks
  const imageBlocks: any[] = [];
  if (imageUrls.front) {
    imageBlocks.push(imageSourceFromUrl(imageUrls.front));
    imageBlocks.push({ type: "text", text: "FRONT VIEW" });
  }
  if (imageUrls.side) {
    imageBlocks.push(imageSourceFromUrl(imageUrls.side));
    imageBlocks.push({ type: "text", text: "SIDE VIEW" });
  }
  if (imageUrls.back) {
    imageBlocks.push(imageSourceFromUrl(imageUrls.back));
    imageBlocks.push({ type: "text", text: "BACK VIEW" });
  }

  if (imageBlocks.length === 0) {
    throw new Error("At least one scan image URL is required");
  }

  // Build user message content
  let userText = "Analyze these body scan photos and provide a detailed zone-by-zone assessment.";
  if (previousScanData) {
    userText += `\n\nPREVIOUS SCAN DATA (for comparison):\nOverall Score: ${previousScanData.overall_score}\nZones:\n${previousScanData.zones.map((z) => `- ${z.zone_name}: ${z.status} (delta: ${z.delta}) - ${z.note}`).join("\n")}`;
  } else {
    userText += "\n\nThis is the user's FIRST scan. Use 'new_baseline' status for all zones.";
  }

  const requestBody = {
    model: "claude-sonnet-4-20250514",
    max_tokens: 2048,
    system: buildSystemPrompt(userContext),
    messages: [
      {
        role: "user",
        content: [...imageBlocks, { type: "text", text: userText }],
      },
    ],
  };

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": config.anthropicApiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `Anthropic API error (${response.status}): ${errorText}`
    );
  }

  const data = (await response.json()) as any;

  // Extract the text content from the response
  const textBlock = data.content?.find(
    (block: any) => block.type === "text"
  );
  if (!textBlock?.text) {
    throw new Error("No text content in Anthropic API response");
  }

  // Parse the JSON from the response text
  const jsonMatch = textBlock.text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error("Could not extract JSON from Claude response");
  }

  const result: DiagnosisResult = JSON.parse(jsonMatch[0]);

  // Validate the response structure
  if (
    typeof result.overall_score !== "number" ||
    typeof result.iris_message !== "string" ||
    !Array.isArray(result.zones)
  ) {
    throw new Error("Invalid diagnosis response structure from Claude");
  }

  // Clamp overall score to 0-100
  result.overall_score = Math.max(0, Math.min(100, result.overall_score));

  // Validate each zone
  const validStatuses = new Set([
    "improved",
    "maintained",
    "declined",
    "new_baseline",
  ]);
  for (const zone of result.zones) {
    if (!validStatuses.has(zone.status)) {
      zone.status = "maintained";
    }
    zone.delta = Math.max(-10, Math.min(10, zone.delta || 0));
  }

  return result;
}
