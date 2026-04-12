"""
notifications/signals.py

Django signal handlers that trigger WhatsApp notifications automatically
when key model events occur.

Connected in notifications/apps.py via AppConfig.ready().
"""

import logging

from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger(__name__)


def _get_notifier():
    """Lazy-import WhatsAppNotifier to avoid circular imports at module load."""
    from notifications.whatsapp_service import WhatsAppNotifier  # noqa: WPS433
    return WhatsAppNotifier()


# ---------------------------------------------------------------------------
# Event signals
# ---------------------------------------------------------------------------

def connect_event_signals():
    """Register signal handlers for the Event model."""
    from events.models import Event  # noqa: WPS433

    @receiver(post_save, sender=Event, weak=False, dispatch_uid='notifications.event_created')
    def on_event_created(sender, instance, created, **kwargs):  # noqa: WPS430
        """Send notifications to all club members when a new event is published."""
        if not created:
            return
        try:
            notifier = _get_notifier()
            notifier.notify_event_created(instance)
        except Exception as exc:  # pylint: disable=broad-except
            logger.exception(
                'Signal on_event_created: failed to send WhatsApp notifications for event %s: %s',
                instance.pk,
                exc,
            )


# ---------------------------------------------------------------------------
# JoinRequest signals
# ---------------------------------------------------------------------------

def connect_join_request_signals():
    """Register signal handlers for the JoinRequest model."""
    from clubs.models import JoinRequest  # noqa: WPS433

    @receiver(post_save, sender=JoinRequest, weak=False, dispatch_uid='notifications.join_request_updated')
    def on_join_request_saved(sender, instance, created, **kwargs):  # noqa: WPS430
        """
        Notify a student when their join request transitions to approved or rejected.

        Note: Django does not pass the previous field value in post_save, so we
        notify whenever the status is approved or rejected (not just on first
        transition).  To avoid duplicate messages you could use pre_save to track
        the previous value, but keeping it simple here is the safer default.
        """
        if created:
            # The request was just submitted — no status update to notify yet.
            return

        if instance.status in ('approved', 'rejected'):
            try:
                notifier = _get_notifier()
                notifier.notify_join_request_update(instance)
            except Exception as exc:  # pylint: disable=broad-except
                logger.exception(
                    'Signal on_join_request_saved: failed to send WhatsApp notification for join request %s: %s',
                    instance.pk,
                    exc,
                )
