from django.contrib import admin
from unfold.admin import ModelAdmin, TabularInline
from .models import Parking, Spot, ParkingEntrance

class ParkingEntranceInline(TabularInline):
    model = ParkingEntrance
    fields = ('address_line', 'latitude', 'longitude') 
    extra = 0
    verbose_name = 'Entrance (for underground parking)'
    verbose_name_plural = 'Entrances (optional - leave empty for street parking)'

@admin.register(Parking)
class ParkingAdmin(ModelAdmin):
    inlines = [ParkingEntranceInline]
    list_display = (
        'name', 'city', 'address', 
        'total_spots', 'available_spots', 
        'rate_per_hour',
    )
    search_fields = ('name', 'city', 'address')
    fields = (
        'name', 'city', 'address', 'rate_per_hour', 
        'polygon_coordinates',
        'tariff_config_json' 
    )
    
    help_texts = {
        'polygon_coordinates': 'JSON array of coordinates: [{"lat": 41.123, "lng": 12.456}, ...]'
    }

@admin.register(Spot)
class SpotAdmin(ModelAdmin):
    list_display = ('id', 'parking', 'floor', 'zone', 'is_occupied')
    list_filter = ('parking', 'floor', 'zone', 'is_occupied')
    search_fields = ('parking__name', 'zone')