from django.contrib import admin
from .models import Club, JoinRequest


@admin.register(Club)
class ClubAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by', 'created_at')
    search_fields = ('name',)
    readonly_fields = ('id', 'created_at')


@admin.register(JoinRequest)
class JoinRequestAdmin(admin.ModelAdmin):
    list_display = ('user', 'club', 'status', 'created_at')
    list_filter = ('status', 'club')
    search_fields = ('user__email', 'club__name')
    readonly_fields = ('id', 'created_at')
