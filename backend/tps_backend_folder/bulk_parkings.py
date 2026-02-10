import os
import django
import random
import math
import json
from django.utils import timezone

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tps_backend.settings")
django.setup()

from parkings.models import Parking, Spot, City  

# Constants
BATCH_SIZE = 100
DEFAULT_RATE = 2.5
DEFAULT_SPOTS_PER_PARKING = 5
MAX_DISTANCE_KM = 10  
POLYGON_SIZE_M = 10   

# 1. Get the test city
try:
    city = City.objects.get(name="0_TEST_CITY")
except City.DoesNotExist:
    print("Test city '0_TEST_CITY' not found. Aborting.")
    exit()

print(f"Creating parkings in city: {city.name} ({city.center_latitude}, {city.center_longitude})")

# 2. Ask user for number of parkings and spots
num_parkings = int(input("How many parkings do you want to create? "))
num_spots = int(input("How many spots per parking? "))

confirm = input(f"Proceed to create {num_parkings} parkings with {num_spots} spots each? (yes/no) ").lower()
if confirm != "yes":
    print("Aborted.")
    exit()

# Utility functions
def random_point_within_radius(lat_center, lon_center, radius_km):
    """Return random lat/lon within a radius (approx.)"""
    # Earth radius in km
    R = 6371
    # Random distance and angle
    d = random.uniform(0, radius_km)
    theta = random.uniform(0, 2 * math.pi)
    
    delta_lat = (d / R) * (180 / math.pi)
    delta_lon = (d / R) * (180 / math.pi) / math.cos(lat_center * math.pi / 180)
    
    return lat_center + delta_lat * math.sin(theta), lon_center + delta_lon * math.cos(theta)

def create_square_polygon(lat_center, lon_center, size_m):
    """Creates a small square polygon around a center point"""
    # Approx. meters to degrees (rough)
    meter_in_deg = 1 / 111_000
    half_size = size_m / 2 * meter_in_deg
    polygon = [
        {"lat": lat_center - half_size, "lng": lon_center - half_size},
        {"lat": lat_center - half_size, "lng": lon_center + half_size},
        {"lat": lat_center + half_size, "lng": lon_center + half_size},
        {"lat": lat_center + half_size, "lng": lon_center - half_size},
    ]
    return polygon

now = timezone.now()
parkings_to_create = []

# 3. Create Parking objects
for i in range(1, num_parkings + 1):
    lat, lon = random_point_within_radius(city.center_latitude, city.center_longitude, MAX_DISTANCE_KM)
    polygon = create_square_polygon(lat, lon, POLYGON_SIZE_M)
    
    parking = Parking(
        name=f"TEST_Parking_{i:03}",
        city=city.name,
        address=f"{i} {city.name} Street",
        rate_per_hour=DEFAULT_RATE,
        latitude=lat,
        longitude=lon,
        polygon_coordinates=json.dumps(polygon)
    )
    parkings_to_create.append(parking)

# 4. Bulk create parkings in batches
print("Creating parkings...")
created_parkings = []
for start in range(0, len(parkings_to_create), BATCH_SIZE):
    batch = parkings_to_create[start:start + BATCH_SIZE]
    Parking.objects.bulk_create(batch)
    created_parkings.extend(batch)
print(f"Created {len(created_parkings)} parkings.")

# 5. Create spots per parking
print("Creating spots for each parking...")
spots_to_create = []

# Take last num_parkings created, ordered by id
last_parkings = Parking.objects.filter(city=city.name).order_by('-id')[:num_parkings]
# reverse to maintain ascending order
last_parkings = reversed(last_parkings)

for parking in last_parkings:
    for s in range(1, num_spots + 1):
        spots_to_create.append(
            Spot(
                parking=parking,
                number=f"{s:03}",
                floor="0"
            )
        )
    # Bulk create spots in batches per parking
    for start in range(0, len(spots_to_create), BATCH_SIZE):
        Spot.objects.bulk_create(spots_to_create[start:start + BATCH_SIZE])
    spots_to_create = []  # reset for next parking

print("Done! All parkings and spots created in 0_TEST_CITY.")
