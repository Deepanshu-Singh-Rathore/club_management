from django.contrib import admin
from django.urls import path, include
from .views import health_check

urlpatterns = [
    path('', health_check, name='root'),
    path('health/', health_check, name='health_check'),
    path('api/health/', health_check, name='api_health_check'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/clubs/', include('clubs.urls')),
]
