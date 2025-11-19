from rest_framework import serializers
from .models import Parking, Spot, ParkingEntrance 

class ParkingEntranceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingEntrance
        fields = ['latitude', 'longitude', 'address_line'] # Campi essenziali per l'app

class SpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = Spot
        fields = '__all__'
        read_only_fields = ['id']

class ParkingSerializer(serializers.ModelSerializer):
    total_spots = serializers.IntegerField(read_only=True)
    available_spots = serializers.IntegerField(read_only=True) 
    rate = serializers.DecimalField(source='rate_per_hour', max_digits=6, decimal_places=2)
    entrances = ParkingEntranceSerializer(many=True, read_only=True) 

    class Meta:
        model = Parking
        fields = [
            'id', 
            'name', 
            'city', 
            'address', 
            'latitude', 
            'longitude',  
            'total_spots', 
            'available_spots',  
            'rate',
            'entrances',
            'tariff_config_json', # NUOVO CAMPO
        ]
        
    def update(self, instance, validated_data):
        # Assicura che rate_per_hour sia aggiornato se ricevi 'rate'
        if 'rate_per_hour' not in validated_data and 'rate' in self.initial_data:
            validated_data['rate_per_hour'] = self.initial_data['rate']
        
        # Aggiorna anche tariff_config_json se presente nel payload
        if 'tariff_config_json' in self.initial_data:
            instance.tariff_config_json = self.initial_data['tariff_config_json']

        return super().update(instance, validated_data)