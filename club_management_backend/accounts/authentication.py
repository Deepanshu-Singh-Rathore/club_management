from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.settings import api_settings
from django.core.cache import cache


class CachedJWTAuthentication(JWTAuthentication):
    """
    Cached JWT Authentication backend.
    Caches resolved user model instances in memory for 60 seconds.
    Eliminates redundant remote database queries on every authenticated API request.
    """
    def get_user(self, validated_token):
        user_id = str(validated_token.get(api_settings.USER_ID_CLAIM) or validated_token.get('user_id') or validated_token.get('id'))
        if not user_id:
            return super().get_user(validated_token)

        cache_key = f"jwt_user_{user_id}"
        user = cache.get(cache_key)

        if user is None:
            user = super().get_user(validated_token)
            if user and user.is_active:
                cache.set(cache_key, user, timeout=60)

        return user
