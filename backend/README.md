# ASCEND Backend API

Node.js + Express + PostgreSQL + Redis backend for the ASCEND body transformation tracker.

## Quick Start

### Prerequisites
- Node.js 20+
- Docker & Docker Compose (for Postgres + Redis)

### 1. Environment Setup

```bash
cp .env.example .env
# Edit .env with your secrets (JWT_SECRET, ANTHROPIC_API_KEY, AWS credentials, etc.)
```

### 2. Start Infrastructure

```bash
docker compose up -d postgres redis
```

### 3. Install & Run

```bash
npm install
npm run migrate
npm run dev
```

The API starts on `http://localhost:3000`. Verify with `GET /health`.

### Full Docker Setup

```bash
docker compose up --build
```

This starts Postgres, Redis, and the API together.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/apple` | No | Apple Sign-In |
| POST | `/auth/register` | No | Email/password registration |
| POST | `/auth/login` | No | Email/password login |
| GET | `/users/me` | Yes | Get current user profile |
| PUT | `/users/me` | Yes | Update profile |
| DELETE | `/users/me` | Yes | Delete account |
| POST | `/scans` | Yes | Create scan + get presigned upload URLs |
| GET | `/scans` | Yes | List user's scans (paginated) |
| GET | `/scans/:id` | Yes | Get scan with diagnoses |
| POST | `/diagnoses` | Yes | Trigger Claude Vision analysis |
| GET | `/diagnoses/:scanId` | Yes | Get diagnosis results |
| GET | `/leaderboard` | Yes | Global/friends/goal leaderboard |
| GET | `/leaderboard/me` | Yes | Current user's rank |
| POST | `/friends/invite` | Yes | Send friend request |
| POST | `/friends/:id/accept` | Yes | Accept friend request |
| GET | `/friends` | Yes | List friends |
| DELETE | `/friends/:id` | Yes | Remove friend |
| GET | `/milestones` | Yes | List milestones |
| POST | `/milestones/claim` | Yes | Claim milestone reward |
| POST | `/milestones/claim-all` | Yes | Claim all unclaimed rewards |

## Authentication

All protected routes require a `Bearer` token in the `Authorization` header:

```
Authorization: Bearer <jwt-token>
```

Tokens are returned from the auth endpoints and expire after 30 days by default.

## Architecture

- **Express** REST API with JWT authentication
- **PostgreSQL** for persistent storage (users, scans, diagnoses, leaderboard, milestones, friends)
- **Redis** for leaderboard caching (5-min TTL) and Bull job queue
- **Bull** queue for async Claude Vision processing
- **AWS S3** for scan image storage (presigned URLs for upload/download)
- **Anthropic Claude Vision** for body composition analysis
- **APNs** for push notifications via HTTP/2

## Deployment

Built to deploy on Fly.io or Railway with minimal changes:
1. Set all environment variables from `.env.example`
2. Provision a Postgres database and Redis instance
3. Run the migration: `npm run migrate`
4. Deploy the Docker image
