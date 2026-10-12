# Deploy and Host Airweave on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/airweave?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=airweave)

[Airweave](https://airweave.ai/) is the open-source context retrieval layer for AI agents. Connect Notion, Slack, GitHub, Google Drive, Gmail, Jira, Linear, HubSpot, Salesforce, databases and 50+ other apps; Airweave syncs them into collections and exposes one search API (instant, classic and agentic tiers) that agents, RAG pipelines and MCP clients can query. This template runs the full self-hosted stack: API, sync worker, Temporal, the Vespa search engine, Svix webhooks, Postgres and Redis, behind a password-protected gateway.

## About Hosting Airweave

The stack is eight services:

- **Airweave** (public): Caddy serving Airweave's web app and proxying `/api` to the backend. It holds the only public domain and the lock (see below).
- **Backend**: the official `airweave-backend` image (pinned to v0.9.73), FastAPI. Runs the database migrations on every boot before Railway's health check passes.
- **Worker**: the same image running the Temporal worker that executes syncs: it pulls data from your sources, chunks and embeds it and writes it to Vespa. Raw sync data goes to its volume.
- **Temporal**: `temporalio/auto-setup`, on the same Postgres (it creates its own `temporal` and `temporal_visibility` databases). The start command registers Airweave's `SyncId` search attribute, which scheduled syncs need.
- **Vespa**: single-node Vespa 8, Airweave's hybrid (vector + BM25) search index. It deploys Airweave's schemas itself on every boot, so no init container is needed.
- **Svix**: the open-source webhook server Airweave uses to deliver sync events to your endpoints.
- **Postgres 16** and **Redis 8**, private network only.

**Airweave has no login of its own when self-hosted.** Its built-in auth needs an Auth0 tenant; without one (`AUTH_ENABLED=false`, upstream's self-host default) every API call acts as the admin. So nothing but the gateway is public, and the gateway requires either:

- **HTTP basic auth** for the browser: user `admin`, password `AIRWEAVE_PASSWORD` (generated), or
- **an `X-API-Key` header** for scripts, SDKs and MCP: the generated `AIRWEAVE_API_KEY`.

Both are on the Airweave service's Variables tab. API keys created inside the Airweave web app are not checked in this mode; use `AIRWEAVE_API_KEY`.

## Common Use Cases

- Giving AI agents and copilots search over a team's Notion, Slack, Drive, GitHub and ticketing data
- A RAG backend that keeps itself in sync with source apps on a schedule
- An MCP search server for Claude, Cursor and other MCP clients over your company knowledge
- Unified semantic and keyword search across many SaaS tools behind one API

## Dependencies for Airweave Hosting

- A **Mistral API key** (required): one key covers embeddings, OCR of PDFs and images, and the search LLM
- Optional: OpenAI key (alternative embeddings), Anthropic or Together AI keys (fallback search LLMs)
- Postgres 16, Redis 8, Temporal, Vespa and Svix (all included, private network only)

### Deployment Dependencies

- [Airweave documentation](https://docs.airweave.ai/)
- [Airweave on GitHub](https://github.com/airweave-ai/airweave)
- [Template source on GitHub](https://github.com/nomideusz/airweave-railway)

### Implementation Details

**Sign in.** Open the Airweave service's domain once all services are green (the first boot runs 150+ migrations and Vespa takes a minute or two to deploy its schemas). Sign in with `admin` and `AIRWEAVE_PASSWORD`.

**Use the API.** Point clients at `https://<your-domain>/api` and send `X-API-Key: <AIRWEAVE_API_KEY>`. With the Python SDK: `AirweaveSDK(api_key=KEY, base_url="https://<your-domain>/api")`. Example:

```
curl -H "X-API-Key: $AIRWEAVE_API_KEY" https://<your-domain>/api/collections/
```

**Why Mistral is required.** Airweave's sync worker will not start without an OCR backend, and its only built-in options are Mistral OCR or a self-hosted Docling server (several GB of RAM). This template uses Mistral for everything so a single `MISTRAL_API_KEY` on the Backend service is enough.

**Embeddings are fixed after the first sync.** The default is `mistral-embed` (1024 dimensions). To use OpenAI instead, set these before the first deploy: `DENSE_EMBEDDER=openai_text_embedding_3_small` and `OPENAI_API_KEY` on the Backend, and `EMBEDDING_DIMENSIONS=1536` on the Vespa service (`3072` for `openai_text_embedding_3_large`). Mistral is still needed for OCR. Changing the model later makes synced data unsearchable, and Airweave refuses to start on a mismatch.

**Search tiers.** Instant search needs only embeddings. Classic and agentic search also call an LLM. `LLM_FALLBACK_CHAIN` on the Backend is preset to Mistral Large, then Claude Sonnet 4.6, then GLM-5 on Together AI. Entries without a key are skipped, so add `ANTHROPIC_API_KEY` or `TOGETHER_API_KEY` if you want fallbacks.

**OAuth sources need your own OAuth app.** In self-hosted mode, sources that sign in with OAuth (Google, Slack, Notion, ...) ask for your own client ID and secret. Register the app with the provider and use the redirect URL Airweave shows. Sources that take an API key or token work directly.

**Back up `ENCRYPTION_KEY`.** It encrypts every stored source credential. Copy it from the Backend service's Variables into your password manager; changing it makes all connected sources unreadable.

**Custom domain.** Add it to the Airweave service, then set `API_FULL_URL` (`https://your-domain/api`) and `APP_FULL_URL` (`https://your-domain`) on the Backend.

**Analytics.** Airweave sends anonymous usage analytics to its PostHog by default; this template sets `ANALYTICS_ENABLED=false`.

**Resources.** Expect about 4.7 GB of RAM at idle (measured on Railway). Vespa uses about 3.4 GB of that (its query container reserves a fixed 1.5 GB Java heap), the Backend and Worker about 450-500 MB each, and Postgres, Temporal, Svix, Redis and the gateway about 450 MB together. That needs a Hobby or Pro plan. Vespa's memory grows with the amount of synced data.

## Why Deploy Airweave on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Airweave on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
