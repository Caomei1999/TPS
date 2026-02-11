from django.urls import path, include
from rest_framework.routers import DefaultRouter
<<<<<<< HEAD
from .views import PlateOCRView, VehicleViewSet, ParkingSessionViewSet

=======
from .views import VehicleViewSet, ParkingSessionViewSet
from .views import VehicleViewSet, ParkingSessionViewSet, PlateOCRView
>>>>>>> 5612cf5c47b9f79de798b873db7883b38aed6333

router = DefaultRouter()
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'sessions', ParkingSessionViewSet, basename='session')

urlpatterns = [
    path('vehicles/plate-ocr/', PlateOCRView.as_view(), name='plate-ocr'),
    path('', include(router.urls)),
    path('plate-ocr/', PlateOCRView.as_view(), name='plate-ocr'),
]