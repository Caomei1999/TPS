from django.urls import path
from .views import (
    ContestFineView,
    PayFineView,
    ProfileView,
    UserFinesView,
    ViolationTypesView, 
    register_user, 
    UserTokenObtainPairView,    
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
    # Auth & Registration
    path('register/', register_user, name='register'),
    
    # Login 
    path('token/user/', UserTokenObtainPairView.as_view(), name='token_user'),
    path('token/manager/', ManagerTokenObtainPairView.as_view(), name='token_manager'),
    path('token/controller/', ControllerTokenObtainPairView.as_view(), name='token_controller'),
    
    # Refresh token 
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # User Profile management
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('delete/', DeleteAccountView.as_view(), name='delete_account'),
    path('password-reset-request/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),

    # Shift Management 
    path('shifts/current/', CurrentShiftView.as_view(), name='current_shift'),
    path('shifts/start/', StartShiftView.as_view(), name='start_shift'),
    path('shifts/end/', EndShiftView.as_view(), name='end_shift'),
    path('shifts/history/', ShiftHistoryView.as_view(), name='shift_history'),
    path('shifts/active-officers/', ActiveOfficersView.as_view(), name='active_officers'),

    # Violations & Fines
    path('violations/report/', ReportViolationView.as_view(), name='report_violation'),
    path('me/fines/', UserFinesView.as_view(), name='user-fines'),
    path('fines/<int:pk>/pay/', PayFineView.as_view(), name='pay-fine'),
    path('fines/<int:pk>/contest/', ContestFineView.as_view(), name='contest-fine'),
    path('violations/types/', ViolationTypesView.as_view(), name='violation_types'),
]