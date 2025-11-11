from django.urls import path
from .views import ProfileView, register_user
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    # Registration endpoint
    path('register/', register_user, name='register'),

    # JWT login endpoints
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Profile endpoint (requires authentication)
    path('profile/', ProfileView.as_view(), name='profile'),
]
