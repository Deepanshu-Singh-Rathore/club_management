from django.contrib import admin

from .models import Event, EventRegistration


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('title', 'club', 'event_date', 'created_by', 'created_at')
    list_filter = ('club',)
    search_fields = ('title', 'club__name')
    readonly_fields = ('id', 'created_at')


@admin.register(EventRegistration)
class EventRegistrationAdmin(admin.ModelAdmin):
    list_display = ('user', 'event', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = ('user__email', 'event__title')
    readonly_fields = ('id', 'created_at')
