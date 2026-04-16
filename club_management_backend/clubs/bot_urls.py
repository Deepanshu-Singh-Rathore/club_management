from django.urls import path
from .twilio_webhook import whatsapp_webhook

urlpatterns = [
    path('whatsapp/', whatsapp_webhook, name='whatsapp-webhook'),
]
