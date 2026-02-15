from rest_framework.routers import DefaultRouter
from .views import ClubViewSet, EventViewSet, RegistrationViewSet

router = DefaultRouter()
router.register(r'clubs', ClubViewSet)
router.register(r'events', EventViewSet)
router.register(r'registrations', RegistrationViewSet)

urlpatterns = router.urls

