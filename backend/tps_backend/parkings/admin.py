from django.contrib import admin
from unfold.admin import ModelAdmin, TabularInline
from .models import Parking, Spot, ParkingEntrance, City

@admin.register(City)
class CityAdmin(ModelAdmin):
    list_display = ('name', 'country', 'parking_count', 'created_at')
    search_fields = ('name', 'country')
    list_filter = ('country',)
    ordering = ('name',)
    
    def parking_count(self, obj):
        """Show how many parkings exist in this city"""
        return Parking.objects.filter(city=obj.name).count()
    parking_count.short_description = "Parkings"
    
    def has_module_permission(self, request):
        """Only superusers can see Cities in admin menu"""
        return request.user.is_superuser
    
    def has_view_permission(self, request, obj=None):
        return request.user.is_superuser
    
    def has_add_permission(self, request):
        return request.user.is_superuser
    
    def has_change_permission(self, request, obj=None):
        return request.user.is_superuser
    
    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser

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