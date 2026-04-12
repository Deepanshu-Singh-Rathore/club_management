"""
notifications/whatsapp_service.py

Service layer for sending WhatsApp notifications via the ClubSphere bot API.

Usage example:
    from notifications.whatsapp_service import WhatsAppNotifier

    notifier = WhatsAppNotifier()
    notifier.send_message('919876543210', 'Hello from ClubSphere!')
"""

import logging
from typing import Iterable

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Helper: build a consistent message about an event (mirrors formatter.js)
# ---------------------------------------------------------------------------

def _format_event_notification(event) -> str:
    """Return a WhatsApp-formatted string for a newly created event."""
    club_name = event.club.name if event.club else 'Your Club'
    date_str  = event.event_date.strftime('%A, %d %B %Y at %I:%M %p') if event.event_date else 'TBA'
    desc_part = f'\n📝 {event.description}' if event.description else ''

    return (
        f'🎉 *New Event from {club_name}!*\n\n'
        f'📌 *{event.title}*{desc_part}\n\n'
        f'📅 *Date:* {date_str}\n\n'
        f'Open the *ClubSphere* app to register and see more details.'
    )


def _format_join_request_update(status: str, club_name: str) -> str:
    """Return a WhatsApp-formatted string for a join request status update."""
    if status == 'approved':
        return (
            f'✅ *Join Request Approved!*\n\n'
            f'Congratulations! Your request to join *{club_name}* has been *approved*. 🎊\n\n'
            f'You are now a member. Open the *ClubSphere* app to explore upcoming events.'
        )
    if status == 'rejected':
        return (
            f'❌ *Join Request Update*\n\n'
            f'Unfortunately, your request to join *{club_name}* has been *declined*.\n\n'
            f"Don't be discouraged — there are plenty of other clubs to explore. 💪"
        )
    return (
        f'ℹ️ *Join Request Update*\n\n'
        f'Your join request for *{club_name}* has been updated to: *{status}*.\n\n'
        f'Open the *ClubSphere* app for more details.'
    )


def _format_event_reminder(event) -> str:
    """Return a WhatsApp-formatted reminder string for an upcoming event."""
    club_name = event.club.name if event.club else 'Your Club'
    date_str  = event.event_date.strftime('%A, %d %B %Y at %I:%M %p') if event.event_date else 'TBA'
    desc_part = f'\n📝 {event.description}' if event.description else ''

    return (
        f'⏰ *Event Reminder!*\n\n'
        f"Don't forget — you are registered for:\n\n"
        f'📌 *{event.title}* by *{club_name}*{desc_part}\n\n'
        f'📅 *When:* {date_str}\n\n'
        f'See you there! Open the *ClubSphere* app for venue and last-minute updates. 🙌'
    )


# ---------------------------------------------------------------------------
# Phone number formatter
# ---------------------------------------------------------------------------

def _clean_phone(raw: str) -> str:
    """
    Strip non-digit characters from a phone number.
    The WhatsApp bot expects a plain digit string (no +, spaces, or hyphens).
    The bot appends @c.us itself.

    Examples:
        '+91 98765 43210' -> '919876543210'
        '919876543210'    -> '919876543210'
    """
    return ''.join(ch for ch in str(raw) if ch.isdigit())


# ---------------------------------------------------------------------------
# WhatsAppNotifier
# ---------------------------------------------------------------------------

class WhatsAppNotifier:
    """
    Thin HTTP client that talks to the Node.js WhatsApp bot API.

    Configuration is read from Django settings:
        WHATSAPP_BOT_URL   – base URL of the bot, e.g. 'http://localhost:3001'
        WHATSAPP_BOT_TOKEN – secret Bearer token for authentication
    """

    def __init__(self):
        self.bot_url = getattr(settings, 'WHATSAPP_BOT_URL', 'http://localhost:3001').rstrip('/')
        self.token   = getattr(settings, 'WHATSAPP_BOT_TOKEN', '')
        self.timeout = 10  # seconds

    # ------------------------------------------------------------------
    # Internal request helper
    # ------------------------------------------------------------------

    def _headers(self) -> dict:
        headers = {'Content-Type': 'application/json'}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'
        return headers

    def _post(self, endpoint: str, payload: dict) -> dict | None:
        """POST to the bot API.  Returns parsed JSON or None on failure."""
        url = f'{self.bot_url}{endpoint}'
        try:
            response = requests.post(url, json=payload, headers=self._headers(), timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.ConnectionError:
            logger.warning('WhatsApp bot is unreachable at %s. Message not sent.', url)
        except requests.exceptions.Timeout:
            logger.warning('WhatsApp bot request timed out for %s.', url)
        except requests.exceptions.HTTPError as exc:
            logger.error('WhatsApp bot returned HTTP %s for %s: %s', exc.response.status_code, url, exc)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception('Unexpected error calling WhatsApp bot at %s: %s', url, exc)
        return None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def send_message(self, phone_number: str, message: str) -> bool:
        """
        Send a single WhatsApp message.

        Args:
            phone_number: Raw phone number string (digits, may include +/spaces).
                          Example: '+91 98765 43210' or '919876543210'.
            message:      Text to send.

        Returns:
            True if the bot accepted the request, False otherwise.
        """
        phone = _clean_phone(phone_number)
        if not phone:
            logger.warning('send_message called with empty/invalid phone number: %r', phone_number)
            return False

        result = self._post('/send-notification', {'phone': phone, 'message': message})
        if result and result.get('success'):
            logger.info('WhatsApp message sent to %s', phone)
            return True
        logger.warning('WhatsApp message to %s was not delivered. Response: %s', phone, result)
        return False

    def send_bulk(self, phone_numbers: Iterable[str], message: str) -> dict:
        """
        Send the same WhatsApp message to multiple phone numbers.

        Args:
            phone_numbers: Iterable of raw phone number strings.
            message:       Text to send.

        Returns:
            Dict with keys 'sent', 'failed', 'results' from the bot (or empty dict on error).
        """
        phones = [_clean_phone(p) for p in phone_numbers if _clean_phone(p)]
        if not phones:
            logger.warning('send_bulk called with no valid phone numbers.')
            return {'sent': 0, 'failed': 0, 'results': []}

        result = self._post('/send-bulk', {'phones': phones, 'message': message})
        if result and result.get('success'):
            logger.info('WhatsApp bulk send: %d sent, %d failed.', result.get('sent', 0), result.get('failed', 0))
            return result
        logger.warning('WhatsApp bulk send did not succeed. Response: %s', result)
        return {'sent': 0, 'failed': len(phones), 'results': []}

    # ------------------------------------------------------------------
    # High-level domain notification methods
    # ------------------------------------------------------------------

    def notify_event_created(self, event) -> None:
        """
        Notify all approved members of the event's club that a new event was created.

        Fetches every user with an approved JoinRequest for the club, then sends
        a bulk notification to those who have a whatsapp_number set.
        """
        try:
            from clubs.models import JoinRequest  # local import avoids circular deps

            members = (
                JoinRequest.objects
                .filter(club=event.club, status=JoinRequest.Status.APPROVED)
                .select_related('user')
            )

            phones = [
                jr.user.whatsapp_number
                for jr in members
                if jr.user.whatsapp_number
            ]

            if not phones:
                logger.info('notify_event_created: no members with WhatsApp numbers for club "%s".', event.club)
                return

            message = _format_event_notification(event)
            self.send_bulk(phones, message)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception('notify_event_created failed for event %s: %s', event.pk, exc)

    def notify_join_request_update(self, join_request) -> None:
        """
        Notify a student that their join request was approved or rejected.
        """
        try:
            user  = join_request.user
            phone = getattr(user, 'whatsapp_number', None)

            if not phone:
                logger.info(
                    'notify_join_request_update: user %s has no WhatsApp number, skipping.', user.email
                )
                return

            club_name = join_request.club.name
            message   = _format_join_request_update(join_request.status, club_name)
            self.send_message(phone, message)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception('notify_join_request_update failed for join request %s: %s', join_request.pk, exc)

    def notify_event_reminder(self, event) -> None:
        """
        Send a reminder to all students who have registered for the event.
        """
        try:
            from events.models import EventRegistration  # local import

            registrations = (
                EventRegistration.objects
                .filter(event=event, status=EventRegistration.Status.REGISTERED)
                .select_related('user')
            )

            phones = [
                reg.user.whatsapp_number
                for reg in registrations
                if reg.user.whatsapp_number
            ]

            if not phones:
                logger.info('notify_event_reminder: no registrants with WhatsApp numbers for event "%s".', event.title)
                return

            message = _format_event_reminder(event)
            self.send_bulk(phones, message)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception('notify_event_reminder failed for event %s: %s', event.pk, exc)
