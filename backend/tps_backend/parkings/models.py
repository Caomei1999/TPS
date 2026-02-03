from django.db import models
from django.db.models.fields import DecimalField
import json

DEFAULT_TARIFF_JSON = """{
    "type": "HOURLY_LINEAR",
    "daily_rate": 20.00,
    "day_base_rate": 2.50,
    "night_base_rate": 1.50,
    "night_start_time": "22:00",
    "night_end_time": "06:00",
    "flex_rules": []
}"""

class Parking(models.Model):
    name = models.CharField(max_length=100)
    city = models.CharField(max_length=50)
    address = models.CharField(max_length=150)
    
    rate_per_hour = models.DecimalField(max_digits=6, decimal_places=2, default=2.5) 

    tariff_config_json = models.TextField(default=DEFAULT_TARIFF_JSON) 

    # Remove single coordinates
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    
    # Add polygon coordinates as JSON
    # Format: [{"lat": 41.123, "lng": 12.456}, {"lat": 41.124, "lng": 12.457}, ...]
    polygon_coordinates = models.TextField(
        default='[]',
        help_text='JSON array of coordinates forming the parking polygon'
    )

    def __str__(self):
        return f"{self.name} ({self.city})"

    def get_polygon_coords(self):
        """Returns polygon coordinates as list of dicts"""
        try:
            return json.loads(self.polygon_coordinates)
        except:
            return []

    def set_polygon_coords(self, coords_list):
        """Sets polygon coordinates from list of dicts"""
        self.polygon_coordinates = json.dumps(coords_list)

    def calculate_centroid(self):
        """Calculate centroid of polygon for marker placement"""
        coords = self.get_polygon_coords()
        if not coords:
            return None, None
        
        lat_sum = sum(c['lat'] for c in coords)
        lng_sum = sum(c['lng'] for c in coords)
        count = len(coords)
        
        return lat_sum / count, lng_sum / count

    def get_marker_position(self):
        """
        Returns marker position (lat, lng):
        - If entrance exists: use entrance coordinates
        - Otherwise: use polygon centroid
        """
        # Check if entrance exists
        entrance = self.entrances.first()
        if entrance:
            return entrance.latitude, entrance.longitude
        
        # Use centroid
        return self.calculate_centroid()

    @property
    def total_spots(self):
        return self.spots.count()

    @property
    def occupied_spots(self):
        return self.spots.filter(is_occupied=True).count()

    @property
    def available_spots(self):
        return self.total_spots - self.occupied_spots

class ParkingEntrance(models.Model):
    parking = models.ForeignKey(
        Parking, 
        on_delete=models.CASCADE, 
        related_name='entrances',
    )
    address_line = models.CharField(max_length=200)
    latitude = models.FloatField()
    longitude = models.FloatField()

    def __str__(self):
        return f"Entrance for {self.parking.name} ({self.address_line})"

    class Meta:
        verbose_name = 'Parking Entrance'
        verbose_name_plural = 'Parking Entrances'

class Spot(models.Model):
    parking = models.ForeignKey(Parking, on_delete=models.CASCADE, related_name='spots')
    number = models.CharField(max_length=20)
    floor = models.CharField(max_length=10, blank=True, default='0') 
    zone = models.CharField(max_length=20, blank=True, null=True)
    is_occupied = models.BooleanField(default=False)

    def __str__(self):
        return f"Spot {self.number} at {self.parking.name}"