from rest_framework.permissions import BasePermission


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.role == 'admin'


class IsClubHead(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.role == 'club_head'


class IsStudent(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.role == 'student'


class IsClubHeadOrAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.role in ['club_head', 'admin']


class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.created_by == request.user or request.user.role == 'admin'