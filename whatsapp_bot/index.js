/**
 * Club Management WhatsApp Bot
 *
 * Commands:
 *   !help          – show available commands
 *   !events        – list upcoming events
 *   !clubs         – list all clubs
 *   !status <id>   – check registration status for an event (UUID)
 *   !register <id> – apply for an event (student only)
 *   !notifications – view your latest notifications
 */

require('dotenv').config();
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
const axios = require('axios');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const API_BASE = process.env.DJANGO_API_URL || 'http://127.0.0.1:8000/api';
const BOT_TOKEN = process.env.BOT_API_TOKEN || '';   // service-account JWT

// ---------------------------------------------------------------------------
// Axios helper – calls the Django backend as a bot service account
// ---------------------------------------------------------------------------

const api = axios.create({
    baseURL: API_BASE,
    headers: {
        Authorization: `Bearer ${BOT_TOKEN}`,
        'Content-Type': 'application/json',
    },
    timeout: 10_000,
});

// Per-user tokens stored in memory (cleared on bot restart)
// phone → { token, refreshToken }
const userSessions = {};

// ---------------------------------------------------------------------------
// WhatsApp client
// ---------------------------------------------------------------------------

const client = new Client({
    authStrategy: new LocalAuth({ clientId: 'club-bot' }),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
    },
});

client.on('qr', (qr) => {
    console.log('\n📱 Scan the QR code below with WhatsApp:\n');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('✅ Club Management WhatsApp Bot is ready!');
});

client.on('auth_failure', (msg) => {
    console.error('❌ Authentication failed:', msg);
});

client.on('disconnected', (reason) => {
    console.warn('⚠️  Bot disconnected:', reason);
});

// ---------------------------------------------------------------------------
// Message handler
// ---------------------------------------------------------------------------

client.on('message', async (msg) => {
    const body = msg.body.trim();
    const phone = msg.from; // e.g. "91XXXXXXXXXX@c.us"

    if (!body.startsWith('!')) return;

    const [cmd, ...args] = body.split(/\s+/);

    try {
        switch (cmd.toLowerCase()) {
            case '!help':
                await msg.reply(helpText());
                break;

            case '!events':
                await handleEvents(msg);
                break;

            case '!clubs':
                await handleClubs(msg);
                break;

            case '!status':
                await handleStatus(msg, args[0]);
                break;

            case '!register':
                await handleRegister(msg, phone, args[0]);
                break;

            case '!notifications':
                await handleNotifications(msg, phone);
                break;

            case '!login':
                await handleLogin(msg, phone, args[0]);
                break;

            default:
                await msg.reply(`❓ Unknown command. Type *!help* to see available commands.`);
        }
    } catch (err) {
        console.error(`Error handling command ${cmd}:`, err.message);
        await msg.reply('⚠️ Something went wrong. Please try again later.');
    }
});

// ---------------------------------------------------------------------------
// Command handlers
// ---------------------------------------------------------------------------

function helpText() {
    return `*🎓 Club Management Bot – Commands*

*!help*               – Show this message
*!events*             – List upcoming events
*!clubs*              – List all clubs
*!status <event-id>*  – Check your registration status for an event
*!register <event-id>*– Apply for an event
*!notifications*      – View your latest notifications
*!login <OTP>*        – Login with OTP sent to your registered email

_First-time users: request an OTP from the college portal, then use !login <OTP>_`;
}

async function handleEvents(msg) {
    const res = await api.get('/clubs/events/');
    const events = res.data;

    if (!events.length) {
        return msg.reply('📅 No upcoming events at the moment.');
    }

    const lines = events.slice(0, 10).map((e, i) => {
        const date = new Date(e.event_date).toLocaleDateString('en-IN', {
            day: 'numeric', month: 'short', year: 'numeric',
        });
        return `*${i + 1}. ${e.title}*\n   🏛 ${e.club_name}\n   📅 ${date}\n   🆔 \`${e.id}\``;
    });

    await msg.reply(`*📋 Upcoming Events:*\n\n${lines.join('\n\n')}\n\nUse *!register <event-id>* to apply.`);
}

async function handleClubs(msg) {
    const res = await api.get('/clubs/');
    const clubs = res.data;

    if (!clubs.length) {
        return msg.reply('🏛 No clubs found.');
    }

    const lines = clubs.slice(0, 15).map((c, i) =>
        `*${i + 1}. ${c.name}*\n   👥 ${c.member_count} members`
    );

    await msg.reply(`*🏛 All Clubs:*\n\n${lines.join('\n\n')}`);
}

async function handleStatus(msg, eventId) {
    if (!eventId) {
        return msg.reply('❗ Please provide an event ID.\nUsage: *!status <event-id>*');
    }

    const phone = msg.from;
    const token = userSessions[phone]?.token;
    if (!token) {
        return msg.reply('🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    try {
        const res = await axios.get(`${API_BASE}/clubs/events/${eventId}/`, {
            headers: { Authorization: `Bearer ${token}` },
        });
        const event = res.data;

        // Check the user's own registration
        const regRes = await axios.get(`${API_BASE}/clubs/events/${eventId}/registrations/pending/`, {
            headers: { Authorization: `Bearer ${token}` },
        });

        await msg.reply(
            `*📋 Event: ${event.title}*\n` +
            `🏛 Club: ${event.club_name}\n` +
            `📅 Date: ${new Date(event.event_date).toLocaleDateString('en-IN')}\n\n` +
            `Your registration is currently shown in pending list: ${regRes.data.length > 0 ? 'Yes (pending)' : 'Approved / Not registered'}`
        );
    } catch (err) {
        if (err.response?.status === 404) {
            await msg.reply('❌ Event not found. Please check the event ID.');
        } else {
            throw err;
        }
    }
}

async function handleRegister(msg, phone, eventId) {
    if (!eventId) {
        return msg.reply('❗ Please provide an event ID.\nUsage: *!register <event-id>*');
    }

    const token = userSessions[phone]?.token;
    if (!token) {
        return msg.reply('🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    try {
        await axios.post(
            `${API_BASE}/clubs/events/${eventId}/apply/`,
            {},
            { headers: { Authorization: `Bearer ${token}` } }
        );
        await msg.reply('✅ Registration submitted successfully! You will be notified once approved.');
    } catch (err) {
        const detail = err.response?.data?.message || err.response?.data?.error;
        if (detail) {
            await msg.reply(`⚠️ ${detail}`);
        } else if (err.response?.status === 403) {
            await msg.reply('🚫 Only students can register for events.');
        } else {
            throw err;
        }
    }
}

async function handleNotifications(msg, phone) {
    const token = userSessions[phone]?.token;
    if (!token) {
        return msg.reply('🔒 You need to login first.\nRequest an OTP from the college portal, then use *!login <OTP>*');
    }

    const res = await axios.get(`${API_BASE}/clubs/notifications/`, {
        headers: { Authorization: `Bearer ${token}` },
    });
    const notifs = res.data;

    if (!notifs.length) {
        return msg.reply('🔔 No notifications yet.');
    }

    const lines = notifs.slice(0, 10).map((n) => {
        const icon = n.type === 'approved' ? '✅' : n.type === 'rejected' ? '❌' : '📩';
        const read = n.is_read ? '' : ' 🔵';
        return `${icon}${read} ${n.message}`;
    });

    await msg.reply(`*🔔 Your Notifications:*\n\n${lines.join('\n')}`);
}

/**
 * !login <OTP>  – exchange a portal OTP for a JWT and store it in the session.
 * The user must have already requested an OTP from the college portal via their
 * registered email address. The bot then calls the VerifyOTP endpoint.
 */
async function handleLogin(msg, phone, otp) {
    if (!otp) {
        return msg.reply('❗ Please provide your OTP.\nUsage: *!login <OTP>*\n\nRequest your OTP at the college portal first.');
    }

    // We need the user's email to verify the OTP. Ask them to send it separately.
    // To keep it simple, we store a pending-login state.
    if (!pendingLogin[phone]) {
        pendingLogin[phone] = { otp };
        return msg.reply(
            '📧 Got your OTP! Now please reply with your *college email address* to complete login.\n\nExample: `student@college.edu`'
        );
    }

    // If we already have a pending entry with otp, this message is the email
    const email = msg.body.trim();
    const storedOtp = pendingLogin[phone]?.otp;
    delete pendingLogin[phone];

    try {
        const res = await axios.post(`${API_BASE}/auth/verify-otp/`, {
            email,
            otp_code: storedOtp,
        });

        userSessions[phone] = {
            token: res.data.access,
            refreshToken: res.data.refresh,
        };

        await msg.reply(`✅ Login successful! Welcome, *${res.data.user?.full_name || email}*\n\nYou can now use *!events*, *!register*, and *!notifications*.`);
    } catch (err) {
        const detail = err.response?.data?.error || err.response?.data?.detail;
        await msg.reply(`❌ Login failed: ${detail || 'Invalid OTP or email.'}\n\nRequest a new OTP from the college portal and try *!login <OTP>* again.`);
    }
}

// Stores { phone: { otp } } while waiting for the email reply
const pendingLogin = {};

// ---------------------------------------------------------------------------
// Override message handler to also catch email replies for pending logins
// ---------------------------------------------------------------------------

client.on('message', async (msg) => {
    const phone = msg.from;
    const body = msg.body.trim();

    // If this user has a pending login waiting for their email
    if (pendingLogin[phone] && !body.startsWith('!')) {
        const email = body;
        const storedOtp = pendingLogin[phone].otp;
        delete pendingLogin[phone];

        try {
            const res = await axios.post(`${API_BASE}/auth/verify-otp/`, {
                email,
                otp_code: storedOtp,
            });

            userSessions[phone] = {
                token: res.data.access,
                refreshToken: res.data.refresh,
            };

            await msg.reply(`✅ Login successful! Welcome, *${res.data.user?.full_name || email}*\n\nYou can now use *!events*, *!register*, and *!notifications*.`);
        } catch (err) {
            const detail = err.response?.data?.error || err.response?.data?.detail;
            await msg.reply(`❌ Login failed: ${detail || 'Invalid OTP or email.'}`);
        }
    }
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

client.initialize();
