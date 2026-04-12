# ClubSphere WhatsApp Bot

Node.js service that sends WhatsApp messages through Whapi.Cloud and exposes
an authenticated HTTP API for the ClubSphere Django backend.

## Features

- Sends single and bulk WhatsApp messages via Whapi.Cloud
- Accepts webhook events from Whapi.Cloud for incoming user messages
- Replies to simple commands: hi, hello, events, help
- Provides backend endpoints for Django notifications:
  - POST /send-notification
  - POST /send-bulk

## Prerequisites

- Node.js 18+
- npm
- A Whapi.Cloud channel token

## Setup

### 1. Install dependencies

```bash
cd whatsapp_bot
npm install
```

### 2. Configure environment

Create .env from .env.example and fill values.

```bash
cp .env.example .env
```

Environment variables:

| Variable | Description | Default |
|---|---|---|
| WHAPI_TOKEN | Whapi.Cloud channel token | required |
| WHAPI_API_URL | Whapi.Cloud API base URL | https://gate.whapi.cloud |
| BOT_API_PORT | Port for this bot service | 3001 |
| BOT_SECRET_TOKEN | Bearer token required for POST endpoints | empty (disabled auth) |

Generate a secure token:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. Run bot

```bash
npm start
```

or during development:

```bash
npm run dev
```

### 4. Configure Whapi webhook

In Whapi.Cloud Dashboard, set webhook URL to:

http://<your-host>:<BOT_API_PORT>/webhook

For local development this is usually exposed using a tunnel.

## API

### GET /health

Returns service status.

Example:

```json
{
  "success": true,
  "status": "ready",
  "timestamp": "2026-04-11T12:34:56.000Z"
}
```

### POST /send-notification

Send one WhatsApp text message.

Headers:

- Authorization: Bearer <BOT_SECRET_TOKEN> (required only if BOT_SECRET_TOKEN is set)

Body:

```json
{
  "phone": "919876543210",
  "message": "Hello from ClubSphere"
}
```

### POST /send-bulk

Send one message to many recipients.

Headers:

- Authorization: Bearer <BOT_SECRET_TOKEN> (required only if BOT_SECRET_TOKEN is set)

Body:

```json
{
  "phones": ["919876543210", "919876543211"],
  "message": "New event announced"
}
```

## Django integration

In backend environment:

WHATSAPP_BOT_URL=http://localhost:3001
WHATSAPP_BOT_TOKEN=<same value as BOT_SECRET_TOKEN>

Django sends notifications through:

- notifications/whatsapp_service.py
- notifications/signals.py

## Command behavior

- hi or hello -> welcome message
- events -> check app for upcoming events
- help -> command list
- other text -> fallback help prompt

## Troubleshooting

- 401 on POST endpoints:
  - Ensure Authorization header matches BOT_SECRET_TOKEN
- ECONNREFUSED from Django:
  - Ensure bot is running and WHATSAPP_BOT_URL is correct
- Messages fail with Whapi error:
  - Verify WHAPI_TOKEN is valid for your active channel
