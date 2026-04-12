from rest_framework.permissions import BasePermission


class IsAdmin(BasePermission):
    """Allow access only to users with the 'admin' role."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == 'admin'
        )


class IsClubHead(BasePermission):
    """Allow access only to users with the 'club_head' role (or admin)."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role in ('club_head', 'admin')
        )


class IsStudent(BasePermission):
    """Allow access only to users with the student role."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role == 'student'
        )


class IsClubHeadOrAdmin(BasePermission):
    """Allow club_head and admin roles."""

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role in ('club_head', 'admin')
        )


class IsOwnerOrAdmin(BasePermission):
    """Object-level: only the owner or an admin may modify."""

    def has_object_permission(self, request, view, obj):
        if request.user.role == 'admin':
            return True
        # obj must expose a `created_by` field
        return getattr(obj, 'created_by', None) == request.user
