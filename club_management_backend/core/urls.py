from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/clubs/', include('clubs.urls')),
    path('api/bot/', include('clubs.bot_urls')),
]
