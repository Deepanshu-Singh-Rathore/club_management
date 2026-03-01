from django.contrib import admin
from .models import Club, Membership, Event


@admin.register(Club)
class ClubAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by', 'created_at')
    search_fields = ('name',)
    readonly_fields = ('id', 'created_at')


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = ('user', 'club', 'joined_at')
    list_filter = ('club',)
    search_fields = ('user__email', 'club__name')
    readonly_fields = ('joined_at',)


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('title', 'club', 'event_date', 'created_by', 'created_at')
    list_filter = ('club',)
    search_fields = ('title', 'club__name')
    readonly_fields = ('id', 'created_at')
