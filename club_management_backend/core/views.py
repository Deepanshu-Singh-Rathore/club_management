from django.http import JsonResponse
from django.views.decorators.http import require_GET


@require_GET
def health_check(request):
    """
    Root / Health check endpoint.
    Provides immediate confirmation that the backend service is healthy.
    """
    return JsonResponse(
        {
            "status": "healthy",
            "service": "ClubSphere Backend API",
            "version": "1.0.0",
            "endpoints": {
                "health": "/health/",
                "admin": "/admin/",
                "auth": {
                    "login": "/api/auth/login/",
                    "register": "/api/auth/register/",
                    "me": "/api/auth/me/",
                    "otp_request": "/api/auth/otp/request/",
                    "otp_verify": "/api/auth/otp/verify/",
                },
                "clubs": {
                    "list": "/api/clubs/",
                    "events": "/api/clubs/events/",
                    "polls": "/api/clubs/polls/",
                    "announcements": "/api/clubs/announcements/",
                },
            },
        },
        status=200,
    )
