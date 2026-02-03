from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ParkingViewSet, SpotViewSet, get_cities_list

router = DefaultRouter()
router.register(r'parkings', ParkingViewSet, basename='parking')
router.register(r'spots', SpotViewSet, basename='spot')

urlpatterns = [
    path('', include(router.urls)),
    path('cities/', get_cities_list, name='cities_list'),
]
