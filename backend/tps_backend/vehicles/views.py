from rest_framework import viewsets, permissions, status, serializers
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Vehicle, ParkingSession
from .serializers import VehicleSerializer, ParkingSessionSerializer, ControllerParkingSessionSerializer # Import the new serializer


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user).order_by('plate') 

    def perform_create(self, serializer):

        serializer.save(user=self.request.user)


class ParkingSessionViewSet(viewsets.ModelViewSet):
    # Uses standard serializer for regular CRUD actions
    serializer_class = ParkingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        is_active_query = self.request.query_params.get('active')

        queryset = ParkingSession.objects.filter(user=user)

        if is_active_query is not None:
            is_active = is_active_query.lower() in ['true', '1']
            queryset = queryset.filter(is_active=is_active)

        return queryset.order_by('-start_time')

    def perform_create(self, serializer):
        vehicle = serializer.validated_data['vehicle']

        # ❗Vehicle ownership control
        if vehicle.user != self.request.user:
            raise serializers.ValidationError("You do not own this vehicle.")

        # ❗Active session control
        if ParkingSession.objects.filter(vehicle=vehicle, is_active=True).exists():
            raise serializers.ValidationError("This vehicle already has an active session.")

        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def end_session(self, request, pk=None):
        session = self.get_object()

        # ❗User control
        if session.user != request.user:
            return Response(
                {'error': 'Not your session.'},
                status=status.HTTP_403_FORBIDDEN
            )

        # ❗Check if already ended
        if not session.is_active:
            return Response(
                {'error': 'Session is already completed.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ❗End session
        session.end_session()
        serializer = self.get_serializer(session)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # UPDATED ACTION: Search Active Session by Plate (Used by Controller App)
    @action(detail=False, methods=['get'])
    def search_by_plate(self, request):
        plate = request.query_params.get('plate', '').upper()
        
        if not plate:
            return Response({'error': 'Plate parameter is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            vehicle = Vehicle.objects.get(plate=plate)
        except Vehicle.DoesNotExist:
            return Response({'status': 'Vehicle Not Found'}, status=status.HTTP_404_NOT_FOUND)

        try:
            session = ParkingSession.objects.get(vehicle=vehicle, is_active=True)
            
            # NOTE: Use the specialized ControllerParkingSessionSerializer
            serializer = ControllerParkingSessionSerializer(session) 
            return Response(serializer.data)
        except ParkingSession.DoesNotExist:
            return Response({'status': 'No Active Session Found'}, status=status.HTTP_404_NOT_FOUND)
        except ParkingSession.MultipleObjectsReturned:
            return Response({'error': 'Multiple active sessions found (System Error)'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)