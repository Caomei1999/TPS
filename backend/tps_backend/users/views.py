from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken 
from rest_framework.permissions import IsAuthenticated
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from .models import CustomUser 
from .serializers import (
    UserRegisterSerializer, 
    UserSerializer,
    ChangePasswordSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer
)
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import Shift
from .serializers import ShiftSerializer
from django.utils import timezone
from vehicles.models import Vehicle, Fine


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role 
        token['allowed_cities'] = user.allowed_cities if user.allowed_cities else []
        return token

    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            # Generic error for authentication failure
            raise serializers.ValidationError({"detail": "Invalid credentials."})

        if self.user.role == 'user' and self.user.violations_count >= 3:
            raise serializers.ValidationError(
                {"detail": "Login denied. Your account is blocked due to excessive violations (3/3)."}
            )

        if not self.user.is_active:
            raise serializers.ValidationError({"detail": "Invalid credentials."})
            
        data['role'] = self.user.role 
        data['allowed_cities'] = self.user.allowed_cities if self.user.allowed_cities else []
        return data
class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Generic login endpoint using CustomTokenObtainPairSerializer
    """
    serializer_class = CustomTokenObtainPairSerializer
    
class ManagerTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer for manager login - only allows manager role OR SUPERUSER
    """
    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Invalid credentials."})

        if self.user.role != 'manager' and self.user.role != 'superuser':
            raise serializers.ValidationError(
                {"detail": "Invalid credentials."}
            )
        
        data['role'] = self.user.role
        return data

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token
class ManagerTokenObtainPairView(TokenObtainPairView):
    """
    Login endpoint specifically for managers
    """
    serializer_class = ManagerTokenObtainPairSerializer

class ControllerTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer for controller login - only allows controller role OR SUPERUSER
    """
    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Invalid credentials."})

        if self.user.role != 'controller' and self.user.role != 'superuser':
            raise serializers.ValidationError(
                {"detail": "Invalid credentials."}
            )
        
        data['role'] = self.user.role
        return data
class ControllerTokenObtainPairView(TokenObtainPairView):
    """
    Login endpoint specifically for controllers
    """
    serializer_class = ControllerTokenObtainPairSerializer
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

class UserTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Serializer for user login - only allows user role
    """
    def validate(self, attrs):
        try:
            data = super().validate(attrs)
        except serializers.ValidationError:
            raise serializers.ValidationError({"detail": "Invalid credentials."})

        if self.user.role != 'user':
            raise serializers.ValidationError(
                {"detail": "Invalid credentials."}
            )

        if self.user.violations_count >= 3:
            raise serializers.ValidationError(
                {"detail": "Login denied. Account blocked due to excessive violations."}
            )
        
        data['role'] = self.user.role
        return data

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

class RegisterUserView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            response_data = {
                'message': 'Registration successful.',
                'user': serializer.data, 
                'tokens': tokens
            }
            return Response(response_data, status=status.HTTP_201_CREATED)
        # Generic error for registration failure
        return Response({"detail": "Registration failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

register_user = RegisterUserView.as_view()

class ProfileView(APIView):
    permission_classes = [IsAuthenticated] 

    def get(self, request):
        user = request.user
        serializer = UserSerializer(user)
        return Response(serializer.data)
    def patch(self, request):
        user = request.user
        serializer = UserSerializer(user, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            old_password = serializer.validated_data['old_password']
            new_password = serializer.validated_data['new_password']
            if not user.check_password(old_password):
                return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(new_password)
            user.save()
            return Response({"message": "Password updated successfully"}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DeleteAccountView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        user = request.user
        user.delete()
        return Response({"message": "Account deleted successfully"}, status=status.HTTP_200_OK)

class PasswordResetRequestView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = CustomUser.objects.get(email=email)
            except CustomUser.DoesNotExist:
                # Always return generic message
                return Response({"message": "If the email exists, a reset code has been sent."}, status=status.HTTP_200_OK)
            token = default_token_generator.make_token(user)
            try:
                send_mail(
                    subject="Password Reset Token",
                    message=f"Your password reset token is: {token}\n\nCopy this token into the app to reset your password.",
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[email],
                    fail_silently=False,
                )
            except Exception as e:
                # Generic error
                return Response({"error": "Failed to send email."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            return Response({"message": "If the email exists, a reset code has been sent."}, status=status.HTTP_200_OK)
        return Response({"detail": "Password reset failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

class PasswordResetConfirmView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Password has been reset successfully."}, status=status.HTTP_200_OK)
        return Response({"detail": "Password reset failed. Please check the information entered."}, status=status.HTTP_400_BAD_REQUEST)

from rest_framework.permissions import IsAuthenticated

class CurrentShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # Check if user is controller, manager, or superuser
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied. Only controllers, managers, and superusers can access shifts."}, status=status.HTTP_403_FORBIDDEN)

        shift = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()
        if not shift:
            return Response({"active": False, "shift": None}, status=status.HTTP_200_OK)

        return Response({"active": True, "shift": ShiftSerializer(shift).data}, status=status.HTTP_200_OK)

class StartShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        # Check if user is controller, manager, or superuser
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied. Only controllers, managers, and superusers can start shifts."}, status=status.HTTP_403_FORBIDDEN)

        # If there's already an OPEN shift, return it
        existing = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()
        if existing:
            return Response(ShiftSerializer(existing).data, status=status.HTTP_200_OK)

        # Normalize start time to the beginning of the current second
        now = timezone.now()
        normalized_start = now.replace(microsecond=0)
        
        shift = Shift.objects.create(officer=user, start_time=normalized_start, status="OPEN")
        return Response(ShiftSerializer(shift).data, status=status.HTTP_201_CREATED)

class EndShiftView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        # Check if user is controller, manager, or superuser
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response({"detail": "Permission denied. Only controllers, managers, and superusers can end shifts."}, status=status.HTTP_403_FORBIDDEN)

        shift_id = request.data.get("shift_id", None)

        if shift_id:
            shift = Shift.objects.filter(id=shift_id, officer=user).first()
        else:
            shift = Shift.objects.filter(officer=user, status="OPEN").order_by("-start_time").first()

        if not shift:
            return Response({"detail": "No active shift found."}, status=status.HTTP_404_NOT_FOUND)

        shift.close()

        duration_seconds = None
        if shift.end_time and shift.start_time:
            duration_seconds = int((shift.end_time - shift.start_time).total_seconds())

        return Response(
            {
                "message": "Shift ended.",
                "shift": ShiftSerializer(shift).data,
                "duration_seconds": duration_seconds,
            },
            status=status.HTTP_200_OK
        )

class ShiftHistoryView(APIView):
    """Get shift history for the authenticated controller"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # Check if user is controller, manager, or superuser
        if user.role not in ['controller', 'manager', 'superuser']:
            return Response(
                {"detail": "Permission denied. Only controllers, managers, and superusers can view shift history."}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # Get all shifts for this officer, ordered by most recent
        shifts = Shift.objects.filter(officer=user).order_by("-start_time")
        
        # Optional: Add pagination or limit
        limit = request.query_params.get('limit', None)
        if limit:
            try:
                shifts = shifts[:int(limit)]
            except ValueError:
                pass

        serializer = ShiftSerializer(shifts, many=True)
        return Response({"shifts": serializer.data}, status=status.HTTP_200_OK)

class ActiveOfficersView(APIView):
    """Get active officers (with OPEN shifts) filtered by city"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        
        # Only managers and superusers can view active officers
        if user.role not in ['manager', 'superuser']:
            return Response(
                {"detail": "Permission denied. Only managers and superusers can view active officers."}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get city filter from query params
        city = request.query_params.get('city', None)
        
        if not city:
            return Response(
                {"detail": "City parameter is required."}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get all officers with OPEN shifts who have access to this city
        active_shifts = Shift.objects.filter(
            status="OPEN"
        ).select_related('officer')
        
        # Filter officers who have permission for this city
        active_officers = []
        for shift in active_shifts:
            officer = shift.officer
            
            # Superusers and officers with this city in allowed_cities
            if officer.is_superuser or (officer.allowed_cities and city in officer.allowed_cities):
                active_officers.append({
                    'id': officer.id,
                    'email': officer.email,
                    'first_name': officer.first_name,
                    'last_name': officer.last_name,
                    'role': officer.role,
                    'shift_id': shift.id,
                    'shift_start': shift.start_time,
                    'shift_duration_seconds': int((timezone.now() - shift.start_time).total_seconds())
                })
        
        return Response({
            'city': city,
            'active_officers': active_officers,
            'count': len(active_officers)
        }, status=status.HTTP_200_OK)

class ReportViolationView(APIView):
    """
    Endpoint for Officers to report a violation for a specific plate.
    POST /api/users/violations/report/
    Body: { "plate": "AB123CD", "reason": "Illegal Parking" }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):

        if request.user.role not in ['controller', 'manager', 'superuser']:
            return Response(
                {"detail": "Permission denied. Only officials can report violations."}, 
                status=status.HTTP_403_FORBIDDEN
            )

        plate = request.data.get('plate')
        if not plate:
            return Response({"detail": "Plate is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:

            vehicle = Vehicle.objects.get(plate__iexact=plate)
            user = vehicle.user
            

            user.violations_count += 1
            

            if user.violations_count >= 3:
                user.is_active = False 
                user.save()

            else:
                user.save()

            fine = Fine.objects.create(
                vehicle=vehicle,
                issued_by=request.user,  
                amount=50.00,            
                reason=request.data.get('reason', 'Illegal Parking'),
                status='unpaid'
            )

            return Response({
                "message": "Violation reported successfully.",
                "fine_id": fine.id,  
                "plate": vehicle.plate,
                "owner_email": user.email,
                "new_violation_count": user.violations_count,
                "account_blocked": not user.is_active  
            }, status=status.HTTP_201_CREATED)

        except Vehicle.DoesNotExist:
            return Response(
                {"detail": "Vehicle not found."}, 
                status=status.HTTP_404_NOT_FOUND
            )