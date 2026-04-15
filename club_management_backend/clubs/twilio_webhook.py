"""
Twilio WhatsApp webhook for ClubSphere.

Twilio sends an HTTP POST to this endpoint when a WhatsApp message arrives.
We parse the body, dispatch to a command handler, and reply using TwiML.

Supported commands (case-insensitive):
  help            – show available commands
  events          – list upcoming events
  clubs           – list all clubs
  leaderboard     – top 10 students by points
  status          – show user's registration statuses
"""

import logging
from xml.etree.ElementTree import Element, SubElement, tostring

from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .models import Club, Event, EventRegistration

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# TwiML response helper
# ---------------------------------------------------------------------------

def twiml_response(body: str) -> HttpResponse:
    """Return a minimal TwiML <Response><Message> reply."""
    response = Element('Response')
    message = SubElement(response, 'Message')
    message.text = body
    xml_bytes = tostring(response, encoding='unicode')
    return HttpResponse(
        f'<?xml version="1.0" encoding="UTF-8"?>{xml_bytes}',
        content_type='text/xml',
    )


# ---------------------------------------------------------------------------
# Command handlers
# ---------------------------------------------------------------------------

def handle_help() -> str:
    return (
        "🎓 *ClubSphere Bot Commands*\n\n"
        "  events       – upcoming events\n"
        "  clubs        – all clubs\n"
        "  leaderboard  – top 10 students\n"
        "  status       – your registrations\n"
        "  help         – this message\n\n"
        "_Visit the portal to register or join clubs._"
    )


def handle_events() -> str:
    events = (
        Event.objects
        .filter(status='upcoming')
        .select_related('club')
        .order_by('event_date')[:10]
    )
    if not events:
        return "📅 No upcoming events right now."

    lines = []
    for e in events:
        date = e.event_date.strftime('%d %b %Y')
        lines.append(f"• *{e.title}* ({e.club.name}) – {date}")
    return "📋 *Upcoming Events:*\n\n" + "\n".join(lines)


def handle_clubs() -> str:
    clubs = Club.objects.prefetch_related('memberships').order_by('name')[:15]
    if not clubs:
        return "🏛 No clubs found."

    lines = [f"• *{c.name}* – {c.memberships.count()} members" for c in clubs]
    return "🏛 *All Clubs:*\n\n" + "\n".join(lines)


def handle_leaderboard() -> str:
    from accounts.models import User
    users = User.objects.filter(is_active=True).order_by('-points')[:10]
    if not users:
        return "🏆 Leaderboard is empty."

    lines = []
    for i, u in enumerate(users, 1):
        medal = {1: '🥇', 2: '🥈', 3: '🥉'}.get(i, f'{i}.')
        name = u.full_name or u.email.split('@')[0]
        lines.append(f"{medal} {name} – {u.points} pts")
    return "🏆 *Leaderboard:*\n\n" + "\n".join(lines)


def handle_status(phone: str) -> str:
    """
    Look up registrations by phone number.
    Users must have their phone_number stored in the portal profile.
    """
    from accounts.models import User
    try:
        # Twilio sends phone as "whatsapp:+91XXXXXXXXXX"
        cleaned = phone.replace('whatsapp:', '').strip()
        user = User.objects.get(phone_number=cleaned)
    except User.DoesNotExist:
        return (
            "🔒 Your phone number is not linked to a ClubSphere account.\n"
            "Please update it in your portal profile."
        )

    regs = (
        EventRegistration.objects
        .filter(user=user)
        .select_related('event')
        .order_by('-created_at')[:10]
    )
    if not regs:
        return "📋 You have no event registrations yet."

    status_emoji = {'pending': '⏳', 'approved': '✅', 'rejected': '❌'}
    lines = []
    for r in regs:
        icon = status_emoji.get(r.status, '?')
        lines.append(f"{icon} {r.event.title} – {r.status}")
    return f"📋 *Your Registrations* ({user.full_name}):\n\n" + "\n".join(lines)


# ---------------------------------------------------------------------------
# Webhook view
# ---------------------------------------------------------------------------

@csrf_exempt
@require_POST
def whatsapp_webhook(request):
    """
    POST /api/bot/whatsapp/
    Called by Twilio for every incoming WhatsApp message.
    """
    body = request.POST.get('Body', '').strip().lower()
    sender = request.POST.get('From', '')

    logger.info("WhatsApp message from %s: %s", sender, body)

    if body in ('help', ''):
        reply = handle_help()
    elif body == 'events':
        reply = handle_events()
    elif body == 'clubs':
        reply = handle_clubs()
    elif body == 'leaderboard':
        reply = handle_leaderboard()
    elif body == 'status':
        reply = handle_status(sender)
    else:
        reply = (
            f"❓ Unknown command: *{body}*\n\n"
            "Type *help* to see available commands."
        )

    return twiml_response(reply)
