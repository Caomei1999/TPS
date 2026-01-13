from django.urls import path
from .views import (
    ProfileView, 
    register_user, 
    CustomTokenObtainPairView, 
    ChangePasswordView, 
    DeleteAccountView,
    PasswordResetRequestView, 
    PasswordResetConfirmView
)
from rest_framework_simplejwt.views import TokenRefreshView
from .views import StartShiftView, EndShiftView, CurrentShiftView

urlpatterns = [
    # Registration endpoint
    path('register/', register_user, name='register'),

    # JWT login endpoints
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Profile endpoint (requires authentication)
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('delete/', DeleteAccountView.as_view(), name='delete_account'),

    # Password Reset Endpoints
    path('password-reset-request/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),

    path('shifts/current/', CurrentShiftView.as_view(), name='current_shift'),
    path('shifts/start/', StartShiftView.as_view(), name='start_shift'),
    path('shifts/end/', EndShiftView.as_view(), name='end_shift'),
]