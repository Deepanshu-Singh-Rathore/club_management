'use strict';

/**
 * formatter.js
 * Utility functions for building human-readable WhatsApp notification messages.
 * All exported functions return a plain string ready to pass to client.sendMessage().
 */

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/**
 * Format a JavaScript Date (or ISO string) as a friendly locale string.
 * Example: "Saturday, 29 March 2026 at 3:00 PM"
 */
function formatDate(rawDate) {
  const date = rawDate instanceof Date ? rawDate : new Date(rawDate);
  if (isNaN(date.getTime())) return String(rawDate);

  const dayName = date.toLocaleDateString('en-IN', { weekday: 'long' });
  const dateStr = date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
  const timeStr = date.toLocaleTimeString('en-IN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });

  return `${dayName}, ${dateStr} at ${timeStr}`;
}

/**
 * Return a relative time label such as "in 2 days" or "in 3 hours".
 * Falls back to the formatted date if it's more than 7 days away.
 */
function relativeTime(rawDate) {
  const now      = Date.now();
  const target   = new Date(rawDate).getTime();
  const diffMs   = target - now;

  if (isNaN(diffMs)) return '';
  if (diffMs <= 0) return 'starting soon';

  const diffMins  = Math.round(diffMs / 60_000);
  const diffHours = Math.round(diffMs / 3_600_000);
  const diffDays  = Math.round(diffMs / 86_400_000);

  if (diffMins < 60)      return `in ${diffMins} minute${diffMins !== 1 ? 's' : ''}`;
  if (diffHours < 24)     return `in ${diffHours} hour${diffHours !== 1 ? 's' : ''}`;
  if (diffDays <= 7)      return `in ${diffDays} day${diffDays !== 1 ? 's' : ''}`;
  return formatDate(rawDate);
}

// ---------------------------------------------------------------------------
// Public formatters
// ---------------------------------------------------------------------------

/**
 * formatEventNotification(event)
 *
 * Called when a new event is created. Notifies all club members.
 *
 * @param {object} event - Django Event instance serialised as a plain object.
 *   Expected keys: title, description, event_date, club.name
 * @returns {string} WhatsApp message text
 */
function formatEventNotification(event) {
  const clubName   = (event.club && event.club.name) ? event.club.name : (event.club_name || 'Your Club');
  const title      = event.title      || 'New Event';
  const desc       = event.description ? `\n📝 ${event.description}` : '';
  const dateStr    = event.event_date  ? formatDate(event.event_date) : 'TBA';
  const relative   = event.event_date  ? ` _(${relativeTime(event.event_date)})_` : '';

  return (
    `🎉 *New Event from ${clubName}!*\n\n` +
    `📌 *${title}*${desc}\n\n` +
    `📅 *Date:* ${dateStr}${relative}\n\n` +
    `Open the *ClubSphere* app to register and see more details.\n` +
    `_Reply *help* for bot commands._`
  );
}

/**
 * formatJoinRequestUpdate(status, clubName)
 *
 * Called when a student's join request is approved or rejected.
 *
 * @param {'approved'|'rejected'} status
 * @param {string} clubName
 * @returns {string} WhatsApp message text
 */
function formatJoinRequestUpdate(status, clubName) {
  const club = clubName || 'the club';

  if (status === 'approved') {
    return (
      `✅ *Join Request Approved!*\n\n` +
      `Congratulations! Your request to join *${club}* has been *approved*. 🎊\n\n` +
      `You are now a member. Open the *ClubSphere* app to explore upcoming events and activities.\n\n` +
      `Welcome to *${club}*! 🚀`
    );
  }

  if (status === 'rejected') {
    return (
      `❌ *Join Request Update*\n\n` +
      `Unfortunately, your request to join *${club}* has been *declined*.\n\n` +
      `Don't be discouraged — there are plenty of other clubs to explore in the *ClubSphere* app. 💪`
    );
  }

  // Fallback for unknown statuses
  return (
    `ℹ️ *Join Request Update*\n\n` +
    `Your join request for *${club}* has been updated to: *${status}*.\n\n` +
    `Open the *ClubSphere* app for more details.`
  );
}

/**
 * formatEventReminder(event)
 *
 * Called to remind registered students about an upcoming event.
 *
 * @param {object} event - Same shape as formatEventNotification.
 * @returns {string} WhatsApp message text
 */
function formatEventReminder(event) {
  const clubName  = (event.club && event.club.name) ? event.club.name : (event.club_name || 'Your Club');
  const title     = event.title      || 'Upcoming Event';
  const desc      = event.description ? `\n📝 ${event.description}` : '';
  const dateStr   = event.event_date  ? formatDate(event.event_date) : 'TBA';
  const relative  = event.event_date  ? ` _(${relativeTime(event.event_date)})_` : '';

  return (
    `⏰ *Event Reminder!*\n\n` +
    `Don't forget — you are registered for:\n\n` +
    `📌 *${title}* by *${clubName}*${desc}\n\n` +
    `📅 *When:* ${dateStr}${relative}\n\n` +
    `See you there! Open the *ClubSphere* app for venue and last-minute updates. 🙌`
  );
}

/**
 * formatWelcomeMessage()
 *
 * Generic welcome message sent to new users or on "hi"/"hello" command.
 *
 * @returns {string} WhatsApp message text
 */
function formatWelcomeMessage() {
  return (
    `👋 *Welcome to ClubSphere!*\n\n` +
    `I am your official club management assistant. 🤖\n\n` +
    `I will keep you updated with:\n` +
    `  • 🎉 New events from your clubs\n` +
    `  • ✅ Club join request updates\n` +
    `  • ⏰ Event reminders\n\n` +
    `📋 *Available Commands*\n` +
    `• *hi* / *hello* — Show this welcome message\n` +
    `• *events*       — Info about upcoming events\n` +
    `• *help*         — Show all commands\n\n` +
    `_Download the ClubSphere app to manage your clubs and events._`
  );
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------
module.exports = {
  formatEventNotification,
  formatJoinRequestUpdate,
  formatEventReminder,
  formatWelcomeMessage,
  // Also export internal helpers so they can be tested independently
  formatDate,
  relativeTime,
};
