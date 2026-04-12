"""
notifications/apps.py

AppConfig for the notifications app.
Connects all Django signals when the app registry is fully loaded.
"""

from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    name           = 'notifications'
    verbose_name   = 'Notifications'
    default_auto_field = 'django.db.models.BigAutoField'

    def ready(self):
        """
        Called once the application registry is fully populated.
        Import and connect signal handlers here to avoid premature model access.
        """
        # Guard against double-registration during test runner setup
        try:
            from notifications.signals import (  # noqa: WPS433
                connect_event_signals,
                connect_join_request_signals,
            )
            connect_event_signals()
            connect_join_request_signals()
        except Exception:  # pylint: disable=broad-except
            # Never crash the entire Django startup because of notification wiring.
            import logging
            logging.getLogger(__name__).exception(
                'NotificationsConfig.ready: failed to connect WhatsApp signals.'
            )
