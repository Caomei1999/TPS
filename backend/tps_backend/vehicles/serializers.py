from rest_framework import serializers
from .models import Vehicle, ParkingSession
from parkings.models import Parking 
from parkings.serializers import ParkingSerializer 

class ControllerVehicleSerializer(serializers.ModelSerializer):
    """
    Minimal serializer for the Controller App: shows only the plate.
    """
    class Meta:
        model = Vehicle
        fields = ['id', 'plate'] # Name is excluded for privacy
        read_only_fields = ['id', 'plate']

class VehicleSerializer(serializers.ModelSerializer):
    """
    Full serializer for the User/Manager App.
    """
    class Meta:
        model = Vehicle
        fields = ['id', 'plate', 'name'] 
        read_only_fields = ['id']

class ParkingSessionSerializer(serializers.ModelSerializer):
    """
    Base session serializer. Uses the full VehicleSerializer by default.
    """
    vehicle = VehicleSerializer(read_only=True)
    parking_lot = ParkingSerializer(read_only=True)
    
    vehicle_id = serializers.PrimaryKeyRelatedField(
        queryset=Vehicle.objects.all(), 
        source='vehicle', 
        write_only=True
    )
    parking_lot_id = serializers.PrimaryKeyRelatedField(
        queryset=Parking.objects.all(),
        source='parking_lot',
        write_only=True
    )
    class Meta:
        model = ParkingSession
        fields = [
            'id', 'vehicle', 'vehicle_id', 'parking_lot', 'parking_lot_id',
            'start_time', 'end_time', 'is_active', 'total_cost'
        ]
        read_only_fields = [
            'id', 'vehicle', 'parking_lot', 'start_time', 
            'end_time', 'is_active', 'total_cost'
        ]

class ControllerParkingSessionSerializer(ParkingSessionSerializer):
    """
    Specialized serializer for the Controller App.
    Uses the minimal ControllerVehicleSerializer.
    """
    vehicle = ControllerVehicleSerializer(read_only=True)

    class Meta(ParkingSessionSerializer.Meta):
        # Inherit fields, but the 'vehicle' field uses the overridden ControllerVehicleSerializer
        pass