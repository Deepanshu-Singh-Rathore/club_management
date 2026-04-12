'use strict';

require('dotenv').config();

const express = require('express');
const { formatWelcomeMessage } = require('./utils/formatter');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const WHAPI_TOKEN   = process.env.WHAPI_TOKEN   || '';
const WHAPI_API_URL = (process.env.WHAPI_API_URL || 'https://gate.whapi.cloud').replace(/\/$/, '');
const BOT_API_PORT  = parseInt(process.env.BOT_API_PORT || '3001', 10);
const BOT_SECRET    = process.env.BOT_SECRET_TOKEN || '';

if (!WHAPI_TOKEN) {
  console.error('[ERROR] WHAPI_TOKEN must be set in .env');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Logging helper
// ---------------------------------------------------------------------------
function log(level, ...args) {
  console.log(`[${new Date().toISOString()}] [${level}]`, ...args);
}

// ---------------------------------------------------------------------------
// Core send helper — calls Whapi.Cloud REST API
// ---------------------------------------------------------------------------

/**
 * Normalise a phone number to plain digits with country code.
 * "+91 98765-43210" → "919876543210"
 */
function cleanPhone(raw) {
  return String(raw).replace(/[^\d]/g, '');
}

async function sendMessage(phone, message) {
  const to = cleanPhone(phone);
  if (!to) throw new Error(`Invalid phone number: "${phone}"`);

  const response = await fetch(`${WHAPI_API_URL}/messages/text`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${WHAPI_TOKEN}`,
      'Content-Type':  'application/json',
    },
    body: JSON.stringify({ to, body: message }),
  });

  const raw = await response.text();
  let data = null;
  try {
    data = raw ? JSON.parse(raw) : null;
  } catch {
    data = { message: raw };
  }

  if (!response.ok) {
    const errMsg = data?.error?.message || data?.message || response.statusText;
    throw new Error(`Whapi error (${response.status}): ${errMsg}`);
  }

  const msgId = data?.message?.id || '(no id)';
  log('INFO', `Message sent to ${to} | id: ${msgId}`);
  return msgId;
}

async function sendBulk(phones, message) {
  const results = [];
  for (const phone of phones) {
    try {
      const id = await sendMessage(phone, message);
      results.push({ phone, success: true, id });
    } catch (err) {
      log('ERROR', `Failed to send to ${phone}: ${err.message}`);
      results.push({ phone, success: false, error: err.message });
    }
  }
  return results;
}

// ---------------------------------------------------------------------------
// Express app
// ---------------------------------------------------------------------------
const app = express();
app.use(express.json());

// ── Auth middleware (for Django → bot calls) ─────────────────────────────────
function authenticate(req, res, next) {
  if (!BOT_SECRET) return next();

  const authHeader = req.headers['authorization'] || '';
  const token      = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';

  if (token !== BOT_SECRET) {
    log('WARN', `Unauthorised request to ${req.method} ${req.path} from ${req.ip}`);
    return res.status(401).json({ success: false, error: 'Unauthorised' });
  }
  next();
}

// ── GET /health ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ success: true, status: 'ready', timestamp: new Date().toISOString() });
});

// ── POST /webhook  (incoming WhatsApp messages forwarded by Whapi.Cloud) ─────
// Set this URL in: Whapi.Cloud Dashboard → Your Channel → Settings → Webhook URL
app.post('/webhook', (req, res) => {
  // Acknowledge immediately
  res.sendStatus(200);

  try {
    const messages = extractIncomingMessages(req.body);
    if (messages.length === 0) return;

    for (const msg of messages) {
      // Ignore outgoing messages (sent by us)
      if (msg.from_me) continue;

      const from = msg.chat_id || msg.from; // e.g. "919876543210@s.whatsapp.net"
      const text = (msg?.text?.body || '').trim().toLowerCase();

      log('INFO', `Incoming from ${from}: "${msg?.text?.body}"`);

      const reply = buildReply(text);
      if (reply) {
        // Strip the @s.whatsapp.net suffix to get a plain phone number for sendMessage
        const phone = from.replace(/@.*$/, '');
        sendMessage(phone, reply).catch((err) =>
          log('ERROR', `Failed to reply to ${from}: ${err.message}`)
        );
      }
    }
  } catch (err) {
    log('ERROR', 'Error processing webhook payload:', err.message);
  }
});

// ── POST /send-notification  (called by Django backend) ──────────────────────
app.post('/send-notification', authenticate, async (req, res) => {
  const { phone, message } = req.body || {};

  if (!phone || !message) {
    return res.status(400).json({ success: false, error: '"phone" and "message" are required.' });
  }

  try {
    const id = await sendMessage(phone, message);
    res.json({ success: true, id, phone, timestamp: new Date().toISOString() });
  } catch (err) {
    log('ERROR', 'POST /send-notification:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── POST /send-bulk  (called by Django backend) ───────────────────────────────
app.post('/send-bulk', authenticate, async (req, res) => {
  const { phones, message } = req.body || {};

  if (!Array.isArray(phones) || phones.length === 0) {
    return res.status(400).json({ success: false, error: '"phones" must be a non-empty array.' });
  }
  if (!message) {
    return res.status(400).json({ success: false, error: '"message" is required.' });
  }

  try {
    const results      = await sendBulk(phones, message);
    const successCount = results.filter((r) => r.success).length;
    res.json({
      success: true,
      sent:    successCount,
      failed:  results.length - successCount,
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    log('ERROR', 'POST /send-bulk:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── 404 catch-all ─────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Endpoint not found.' });
});

// ---------------------------------------------------------------------------
// Incoming message reply builders
// ---------------------------------------------------------------------------
function buildReply(text) {
  if (text === 'hi' || text === 'hello') {
    return formatWelcomeMessage();
  }
  if (text === 'events') {
    return (
      '📅 *Upcoming Events*\n\n' +
      'To view all upcoming events, open the *ClubSphere* app.\n\n' +
      'Reply *help* to see all available commands.'
    );
  }
  if (text === 'help') return buildHelpMessage();

  return "I didn't understand that. Reply *help* to see what I can do. 😊";
}

function extractIncomingMessages(payload) {
  if (!payload) return [];
  if (Array.isArray(payload.messages)) return payload.messages;

  if (payload.messages && typeof payload.messages === 'object') {
    return Object.values(payload.messages);
  }

  if (payload.message && typeof payload.message === 'object') {
    return [payload.message];
  }

  if (payload.chat_id || payload.from || payload.text) {
    return [payload];
  }

  return [];
}

function buildHelpMessage() {
  return (
    '📋 *Available Commands*\n\n' +
    '• *hi* / *hello* — Show welcome message\n' +
    '• *events*       — Info about upcoming events\n' +
    '• *help*         — Show this list\n\n' +
    '_For full functionality, open the ClubSphere app._'
  );
}

// ---------------------------------------------------------------------------
// Start server
// ---------------------------------------------------------------------------
app.listen(BOT_API_PORT, () => {
  log('INFO', `ClubSphere WhatsApp Bot running on port ${BOT_API_PORT}`);
  log('INFO', `Whapi.Cloud API: ${WHAPI_API_URL}`);
  log('INFO', `Webhook endpoint: POST http://localhost:${BOT_API_PORT}/webhook`);
  log('INFO', 'Set this webhook URL in: Whapi.Cloud Dashboard → Channel → Settings');
});
