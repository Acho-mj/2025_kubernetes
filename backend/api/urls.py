from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NameViewSet, health_check

router = DefaultRouter()
router.register(r'names', NameViewSet, basename='name')

urlpatterns = [
    path('health/', health_check, name='health-check'),
    path('', include(router.urls)),
]

