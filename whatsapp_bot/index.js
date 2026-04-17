/**
 * Club Management WhatsApp Bot (Twilio)
 *
 * Commands (all users):
 *   !help                – show available commands
 *   !events              – list upcoming events
 *   !clubs               – list all clubs
 *   !status <id>         – check registration status for an event
 *   !register <id>       – apply for an event
 *   !notifications       – view your latest notifications
 *   !login <OTP>         – login with OTP sent to your registered email
 *
 * Admin-only commands (requires !login first):
 *   !poll <question>     – broadcast an event suggestion request to all members
 *   !viewsuggestions     – view all collected poll responses
 *   !endpoll             – close the active poll
 */

require('dotenv').config();
const express = require('express');
const twilio = require('twilio');
const axios = require('axios');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const API_BASE = process.env.DJANGO_API_URL || 'http://127.0.0.1:8000/api';
const BOT_TOKEN = process.env.BOT_API_TOKEN || '';
const ACCOUNT_SID = process.env.ACCOUNT_SID;
const AUTH_TOKEN = process.env.AUTH_TOKEN;
const TWILIO_NUMBER = process.env.TWILIO_WHATSAPP_NUMBER || 'whatsapp:+14155238886';
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Clients
// ---------------------------------------------------------------------------

const twilioClient = twilio(ACCOUNT_SID, AUTH_TOKEN);

// Bot service-account API (admin role)
const api = axios.create({
    baseURL: API_BASE,
    headers: {
        Authorization: `Bearer ${BOT_TOKEN}`,
        'Content-Type': 'application/json',
    },
    timeout: 10_000,
});

// ---------------------------------------------------------------------------
// In-memory state
// ---------------------------------------------------------------------------

// phone → { token, refreshToken, role }
const userSessions = {};

// phone → { otp }  (waiting for user to send their email)
const pendingLogin = {};

// pollId → { question, responses: [{ phone, name, answer }], adminPhone, active }
const activePolls = {};
let pollCounter = 0;

// phone → pollId  (user has been sent a poll and we await their reply)
const pendingPollResponse = {};

// ---------------------------------------------------------------------------
// Express + Twilio webhook
// ---------------------------------------------------------------------------

const app = express();
app.use(express.urlencoded({ extended: false }));
app.use(express.json());

app.post('/webhook', (req, res) => {
    // Acknowledge immediately with empty TwiML
    res.set('Content-Type', 'text/xml');
    res.send('<Response></Response>');

    const from = req.body.From || '';   // "whatsapp:+91XXXXXXXXXX"
    const body = (req.body.Body || '').trim();

    handleMessage(from, body).catch(err => {
        console.error('Unhandled error in handleMessage:', err.message);
    });
});

app.listen(PORT, () => {
    console.log(`✅ Club Management WhatsApp Bot listening on port ${PORT}`);
    console.log(`   Webhook URL: POST http://localhost:${PORT}/webhook`);
    console.log(`   Expose via ngrok: ngrok http ${PORT}`);
});

// ---------------------------------------------------------------------------
// Core message dispatcher
// ---------------------------------------------------------------------------

async function handleMessage(from, body) {
    // Priority 1: user has a pending poll waiting for their answer
    if (pendingPollResponse[from] && !body.startsWith('!')) {
        return handlePollResponse(from, body);
    }

    // Priority 2: user is in the middle of the login flow (waiting for email)
    if (pendingLogin[from] && !body.startsWith('!')) {
        return handleLoginEmail(from, body);
    }

    if (!body.startsWith('!')) return;

    const [cmd, ...args] = body.split(/\s+/);

    try {
        switch (cmd.toLowerCase()) {
            case '!help':
                await send(from, helpText(from));
                break;
            case '!events':
                await handleEvents(from);
                break;
            case '!clubs':
                await handleClubs(from);
                break;
            case '!status':
                await handleStatus(from, args[0]);
                break;
            case '!register':
                await handleRegister(from, args[0]);
                break;
            case '!notifications':
                await handleNotifications(from);
                break;
            case '!login':
                await handleLogin(from, args[0]);
                break;
            case '!poll':
                await handlePoll(from, args.join(' '));
                break;
            case '!viewsuggestions':
                await handleViewSuggestions(from);
                break;
            case '!endpoll':
                await handleEndPoll(from);
                break;
            default:
                await send(from, '❓ Unknown command. Type *!help* to see available commands.');
        }
    } catch (err) {
        console.error(`Error handling "${cmd}":`, err.message);
        await send(from, '⚠️ Something went wrong. Please try again later.');
    }
}

// ---------------------------------------------------------------------------
// Helper: send WhatsApp message via Twilio
// ---------------------------------------------------------------------------

async function send(to, body) {
    const toFormatted = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;
    await twilioClient.messages.create({
        from: TWILIO_NUMBER,
        to: toFormatted,
        body,
    });
}

// ---------------------------------------------------------------------------
// Helper: check if logged-in user is admin
// ---------------------------------------------------------------------------

function isAdmin(phone) {
    return userSessions[phone]?.role === 'admin';
}

// ---------------------------------------------------------------------------
// !help
// ---------------------------------------------------------------------------

function helpText(phone) {
    const adminSection = isAdmin(phone)
        ? '\n\n*👑 Admin Commands:*\n*!poll <question>*       – Ask members for event suggestions\n*!viewsuggestions*      – View collected suggestions\n*!endpoll*              – Close the active poll'
        : '';

    return `*🎓 Club Management Bot – Commands*

*!help*                – Show this message
*!events*              – List upcoming events
*!clubs*               – List all clubs
*!status <event-id>*   – Check your registration status
*!register <event-id>* – Apply for an event
*!notifications*       – View your latest notifications
*!login <OTP>*         – Login with OTP from the college portal

_First-time: request an OTP at the college portal, then use !login <OTP>_${adminSection}`;
}

// ---------------------------------------------------------------------------
// !events
// ---------------------------------------------------------------------------

async function handleEvents(phone) {
    const res = await api.get('/clubs/events/');
    const events = res.data;

    if (!events.length) {
        return send(phone, '📅 No upcoming events at the moment.');
    }

    const lines = events.slice(0, 10).map((e, i) => {
        const date = new Date(e.event_date).toLocaleDateString('en-IN', {
            day: 'numeric', month: 'short', year: 'numeric',
        });
        return `*${i + 1}. ${e.title}*\n   🏛 ${e.club_name}\n   📅 ${date}\n   🆔 \`${e.id}\``;
    });

    await send(phone, `*📋 Upcoming Events:*\n\n${lines.join('\n\n')}\n\nUse *!register <event-id>* to apply.`);
}

// ---------------------------------------------------------------------------
// !clubs
// ---------------------------------------------------------------------------

async function handleClubs(phone) {
    const res = await api.get('/clubs/');
    const clubs = res.data;

    if (!clubs.length) {
        return send(phone, '🏛 No clubs found.');
    }

    const lines = clubs.slice(0, 15).map((c, i) =>
        `*${i + 1}. ${c.name}*\n   👥 ${c.member_count} members`
    );

    await send(phone, `*🏛 All Clubs:*\n\n${lines.join('\n\n')}`);
}

// ---------------------------------------------------------------------------
// !status <eventId>
// ---------------------------------------------------------------------------

async function handleStatus(phone, eventId) {
    if (!eventId) {
        return send(phone, '❗ Please provide an event ID.\nUsage: *!status <event-id>*');
    }

    const token = userSessions[phone]?.token;
    if (!token) {
        return send(phone, '🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    try {
        const [eventRes, regRes] = await Promise.all([
            axios.get(`${API_BASE}/clubs/events/${eventId}/`, { headers: { Authorization: `Bearer ${token}` } }),
            axios.get(`${API_BASE}/clubs/events/${eventId}/pending/`, { headers: { Authorization: `Bearer ${token}` } }),
        ]);

        const event = eventRes.data;
        const isPending = regRes.data.length > 0;

        await send(phone,
            `*📋 Event: ${event.title}*\n` +
            `🏛 Club: ${event.club_name}\n` +
            `📅 Date: ${new Date(event.event_date).toLocaleDateString('en-IN')}\n\n` +
            `Your status: ${isPending ? '⏳ Pending approval' : '✅ Approved / Not registered'}`
        );
    } catch (err) {
        if (err.response?.status === 404) {
            await send(phone, '❌ Event not found. Please check the event ID.');
        } else {
            throw err;
        }
    }
}

// ---------------------------------------------------------------------------
// !register <eventId>
// ---------------------------------------------------------------------------

async function handleRegister(phone, eventId) {
    if (!eventId) {
        return send(phone, '❗ Please provide an event ID.\nUsage: *!register <event-id>*');
    }

    const token = userSessions[phone]?.token;
    if (!token) {
        return send(phone, '🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    try {
        await axios.post(
            `${API_BASE}/clubs/events/${eventId}/apply/`,
            {},
            { headers: { Authorization: `Bearer ${token}` } }
        );
        await send(phone, '✅ Registration submitted! You will be notified once approved.');
    } catch (err) {
        const detail = err.response?.data?.message || err.response?.data?.error;
        if (detail) {
            await send(phone, `⚠️ ${detail}`);
        } else if (err.response?.status === 403) {
            await send(phone, '🚫 Only students can register for events.');
        } else {
            throw err;
        }
    }
}

// ---------------------------------------------------------------------------
// !notifications
// ---------------------------------------------------------------------------

async function handleNotifications(phone) {
    const token = userSessions[phone]?.token;
    if (!token) {
        return send(phone, '🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    const res = await axios.get(`${API_BASE}/clubs/notifications/`, {
        headers: { Authorization: `Bearer ${token}` },
    });
    const notifs = res.data;

    if (!notifs.length) {
        return send(phone, '🔔 No notifications yet.');
    }

    const lines = notifs.slice(0, 10).map((n) => {
        const icon = n.type === 'approved' ? '✅' : n.type === 'rejected' ? '❌' : '📩';
        const dot = n.is_read ? '' : ' 🔵';
        return `${icon}${dot} ${n.message}`;
    });

    await send(phone, `*🔔 Your Notifications:*\n\n${lines.join('\n')}`);
}

// ---------------------------------------------------------------------------
// !login <OTP>  →  then awaits email reply
// ---------------------------------------------------------------------------

async function handleLogin(phone, otp) {
    if (!otp) {
        return send(phone, '❗ Please provide your OTP.\nUsage: *!login <OTP>*\n\nRequest your OTP at the college portal first.');
    }

    pendingLogin[phone] = { otp };
    await send(phone,
        '📧 Got your OTP! Now please reply with your *college email address* to complete login.\n\nExample: student@college.edu'
    );
}

async function handleLoginEmail(phone, email) {
    const storedOtp = pendingLogin[phone]?.otp;
    delete pendingLogin[phone];

    try {
        const res = await axios.post(`${API_BASE}/auth/verify-otp/`, {
            email,
            otp_code: storedOtp,
        });

        const user = res.data.user;
        userSessions[phone] = {
            token: res.data.access,
            refreshToken: res.data.refresh,
            role: user?.role || 'student',
        };

        const adminNote = user?.role === 'admin' ? '\n\n👑 Admin commands unlocked. Type *!help* to see them.' : '';
        await send(phone, `✅ Login successful! Welcome, *${user?.full_name || email}*${adminNote}`);
    } catch (err) {
        const detail = err.response?.data?.error || err.response?.data?.detail;
        await send(phone, `❌ Login failed: ${detail || 'Invalid OTP or email.'}\n\nRequest a new OTP and try *!login <OTP>* again.`);
    }
}

// ---------------------------------------------------------------------------
// !poll <question>  (admin only)
// ---------------------------------------------------------------------------

async function handlePoll(phone, question) {
    if (!userSessions[phone]?.token) {
        return send(phone, '🔒 You need to login first. Use *!login <OTP>*');
    }
    if (!isAdmin(phone)) {
        return send(phone, '🚫 Only admins can send polls.');
    }
    if (!question) {
        return send(phone, '❗ Please provide a question.\nUsage: *!poll What kind of events do you want next semester?*');
    }

    // Check for already-active poll
    const existing = Object.values(activePolls).find(p => p.active);
    if (existing) {
        return send(phone,
            `⚠️ There is already an active poll:\n\n"${existing.question}"\n\nClose it first with *!endpoll* before starting a new one.`
        );
    }

    // Fetch all users with phone numbers from Django
    let members = [];
    try {
        const res = await api.get('/auth/admin/users/');
        members = res.data.filter(u => u.phone_number && u.is_active);
    } catch (err) {
        console.error('Failed to fetch users for poll:', err.message);
        return send(phone, '⚠️ Could not fetch member list. Make sure BOT_API_TOKEN has admin role.');
    }

    if (!members.length) {
        return send(phone, '⚠️ No members with registered phone numbers found.');
    }

    pollCounter += 1;
    const pollId = `poll_${pollCounter}`;
    activePolls[pollId] = {
        question,
        responses: [],
        adminPhone: phone,
        active: true,
        createdAt: new Date().toISOString(),
    };

    // Send poll message to each member
    const pollMessage =
        `📊 *Event Suggestion Request*\n\n` +
        `The admin wants to know:\n_"${question}"_\n\n` +
        `Please reply with your suggestion! Your response will be sent to the admin.\n` +
        `_(Just type your reply — no need for any command prefix)_`;

    let sent = 0;
    for (const member of members) {
        const memberPhone = normalizePhone(member.phone_number);
        if (!memberPhone) continue;
        try {
            await send(memberPhone, pollMessage);
            pendingPollResponse[memberPhone] = pollId;
            sent++;
        } catch (err) {
            console.warn(`Could not send poll to ${memberPhone}:`, err.message);
        }
    }

    await send(phone,
        `✅ Poll sent to *${sent}* member(s)!\n\n` +
        `Question: _"${question}"_\n\n` +
        `Use *!viewsuggestions* to see responses as they come in.\n` +
        `Use *!endpoll* to close the poll.`
    );
}

// ---------------------------------------------------------------------------
// Poll response handler (called when a user replies without a ! command)
// ---------------------------------------------------------------------------

async function handlePollResponse(phone, answer) {
    const pollId = pendingPollResponse[phone];
    delete pendingPollResponse[phone];

    const poll = activePolls[pollId];
    if (!poll || !poll.active) {
        return; // Poll ended before reply arrived
    }

    // Try to get the user's name from their session, else use phone
    const name = userSessions[phone]
        ? `Logged-in user (${phone})`
        : phone;

    poll.responses.push({ phone, name, answer, at: new Date().toISOString() });

    await send(phone, '✅ Thank you! Your suggestion has been recorded and sent to the admin.');

    // Notify admin of new response
    try {
        await send(poll.adminPhone,
            `📩 *New suggestion received!*\n\nFrom: ${phone}\nSuggestion: _"${answer}"_\n\n` +
            `Total responses so far: ${poll.responses.length}\nUse *!viewsuggestions* to see all.`
        );
    } catch (err) {
        console.warn('Could not notify admin of poll response:', err.message);
    }
}

// ---------------------------------------------------------------------------
// !viewsuggestions  (admin only)
// ---------------------------------------------------------------------------

async function handleViewSuggestions(phone) {
    if (!userSessions[phone]?.token) {
        return send(phone, '🔒 You need to login first. Use *!login <OTP>*');
    }
    if (!isAdmin(phone)) {
        return send(phone, '🚫 Only admins can view suggestions.');
    }

    const polls = Object.values(activePolls);
    if (!polls.length) {
        return send(phone, '📊 No polls have been created yet. Use *!poll <question>* to start one.');
    }

    const lines = [];
    for (const poll of polls) {
        const status = poll.active ? '🟢 Active' : '🔴 Closed';
        lines.push(`*${status}* – "${poll.question}"\n📅 ${new Date(poll.createdAt).toLocaleString('en-IN')}\n📬 ${poll.responses.length} response(s)`);

        if (poll.responses.length) {
            poll.responses.forEach((r, i) => {
                lines.push(`  ${i + 1}. ${r.answer}  _(${r.phone})_`);
            });
        } else {
            lines.push('  _(No responses yet)_');
        }
    }

    await send(phone, `*📊 Event Suggestion Poll Results:*\n\n${lines.join('\n\n')}`);
}

// ---------------------------------------------------------------------------
// !endpoll  (admin only)
// ---------------------------------------------------------------------------

async function handleEndPoll(phone) {
    if (!userSessions[phone]?.token) {
        return send(phone, '🔒 You need to login first. Use *!login <OTP>*');
    }
    if (!isAdmin(phone)) {
        return send(phone, '🚫 Only admins can close polls.');
    }

    const poll = Object.values(activePolls).find(p => p.active);
    if (!poll) {
        return send(phone, '⚠️ No active poll to close.');
    }

    poll.active = false;

    // Clear any pending responses from members who haven't replied yet
    for (const [memberPhone, pId] of Object.entries(pendingPollResponse)) {
        if (activePolls[pId] === poll) {
            delete pendingPollResponse[memberPhone];
            try {
                await send(memberPhone, '📊 The event suggestion poll has been closed. Thank you!');
            } catch (_) { /* ignore */ }
        }
    }

    await send(phone,
        `🔴 Poll closed!\n\n` +
        `Question: _"${poll.question}"_\n` +
        `Total responses: *${poll.responses.length}*\n\n` +
        `Use *!viewsuggestions* to see the full summary.`
    );
}

// ---------------------------------------------------------------------------
// Utility: normalize phone number to whatsapp: format
// ---------------------------------------------------------------------------

function normalizePhone(phone) {
    if (!phone) return null;
    // Strip non-digit chars, then prepend whatsapp:+
    const digits = phone.replace(/\D/g, '');
    if (!digits) return null;
    return `whatsapp:+${digits}`;
}
