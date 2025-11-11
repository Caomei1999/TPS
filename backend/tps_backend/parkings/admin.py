from django.contrib import admin
from .models import Parking, Spot

# Register Parking model
@admin.register(Parking)
class ParkingAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'address', 'total_spots', 'occupied_spots', 'rate_per_hour')
    search_fields = ('name', 'city', 'address')

# Register Spot model
@admin.register(Spot)
class SpotAdmin(admin.ModelAdmin):
    list_display = ('id', 'parking', 'floor', 'zone', 'is_occupied')
    list_filter = ('parking', 'floor', 'zone', 'is_occupied')
    search_fields = ('parking__name', 'zone')
