from django.urls import path
from .views import (
    ProfileView, 
    register_user, 
    CustomTokenObtainPairView,
    ManagerTokenObtainPairView,
    ControllerTokenObtainPairView,
    ChangePasswordView, 
    DeleteAccountView,
    PasswordResetRequestView, 
    PasswordResetConfirmView,
    StartShiftView, 
    EndShiftView, 
    CurrentShiftView,
    ShiftHistoryView,
    ActiveOfficersView,
    ReportViolationView
)
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    # Registration endpoint
    path('register/', register_user, name='register'),

    # JWT login endpoints - generic (for admin/testing)
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # Role-specific login endpoints
    path('token/manager/', ManagerTokenObtainPairView.as_view(), name='token_obtain_pair_manager'),
    path('token/controller/', ControllerTokenObtainPairView.as_view(), name='token_obtain_pair_controller'),

    
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
    path('shifts/history/', ShiftHistoryView.as_view(), name='shift_history'),
    path('shifts/active-officers/', ActiveOfficersView.as_view(), name='active_officers'),
    path('violations/report/', ReportViolationView.as_view(), name='report_violation'),
]