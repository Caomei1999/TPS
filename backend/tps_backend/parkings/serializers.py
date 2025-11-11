from rest_framework import serializers
from .models import Parking, Spot

class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'
        read_only_fields = ['id']

class ParkingSerializer(serializers.ModelSerializer):
    total_spots = serializers.IntegerField(read_only=True)
    occupied_spots = serializers.IntegerField(read_only=True)
    rate = serializers.DecimalField(source='rate_per_hour', max_digits=6, decimal_places=2)

    class Meta:
        model = Parking
        fields = ['id', 'name', 'city', 'address', 'total_spots', 'occupied_spots', 'rate']
