import json
import random
from shapely.geometry import Polygon, Point, box
from shapely.ops import unary_union
import math

# Turin city center approximate bounds
TURIN_BOUNDS = {
    'min_lat': 45.0200,
    'max_lat': 45.1100,
    'min_lon': 7.6200,
    'max_lon': 7.7200
}

# Parking configuration
PARKING_CONFIG = {
    'avg_size_meters': 80,  # Average parking zone size
    'size_variation': 0.4,   # 40% size variation
    'coverage': 0.15,        # 15% of area should be parkings
    'types': ['street', 'lot', 'garage', 'residential'],
    'type_weights': [0.5, 0.25, 0.15, 0.1]
}

PRICING = {
    'street': {'min': 1.0, 'max': 2.5},
    'lot': {'min': 1.5, 'max': 3.0},
    'garage': {'min': 2.0, 'max': 4.0},
    'residential': {'min': 0.5, 'max': 1.5}
}

def meters_to_degrees(meters, latitude):
    """Convert meters to degrees at given latitude"""
    lat_degree = 111320  # meters per degree latitude
    lon_degree = 111320 * math.cos(math.radians(latitude))
    return meters / lat_degree, meters / lon_degree

def generate_random_polygon(center_lat, center_lon, size_meters):
    """Generate a realistic parking polygon"""
    lat_offset, lon_offset = meters_to_degrees(size_meters / 2, center_lat)
    
    # Create variations: rectangular, L-shaped, or irregular
    shape_type = random.choice(['rectangle', 'rectangle', 'L-shape', 'irregular'])
    
    if shape_type == 'rectangle':
        # Rectangular parking (most common)
        aspect = random.uniform(1.5, 4.0)  # Length to width ratio
        if random.random() > 0.5:
            lat_size, lon_size = lat_offset, lon_offset * aspect
        else:
            lat_size, lon_size = lat_offset * aspect, lon_offset
        
        rotation = random.uniform(0, 45)  # Random rotation
        coords = [
            [center_lon - lon_size, center_lat - lat_size],
            [center_lon + lon_size, center_lat - lat_size],
            [center_lon + lon_size, center_lat + lat_size],
            [center_lon - lon_size, center_lat + lat_size],
            [center_lon - lon_size, center_lat - lat_size]
        ]
    
    elif shape_type == 'L-shape':
        # L-shaped parking
        coords = [
            [center_lon - lon_offset, center_lat - lat_offset],
            [center_lon, center_lat - lat_offset],
            [center_lon, center_lat],
            [center_lon + lon_offset, center_lat],
            [center_lon + lon_offset, center_lat + lat_offset],
            [center_lon - lon_offset, center_lat + lat_offset],
            [center_lon - lon_offset, center_lat - lat_offset]
        ]
    
    else:
        # Irregular shape (slight variations)
        num_points = random.randint(5, 7)
        angles = sorted([random.uniform(0, 360) for _ in range(num_points)])
        coords = []
        for angle in angles:
            r = random.uniform(0.7, 1.0)
            rad = math.radians(angle)
            lat = center_lat + lat_offset * r * math.cos(rad)
            lon = center_lon + lon_offset * r * math.sin(rad)
            coords.append([lon, lat])
        coords.append(coords[0])  # Close the polygon
    
    return coords

def generate_parking_grid():
    """Generate parking zones in a grid pattern across Turin"""
    parkings = []
    
    # Calculate grid size
    lat_range = TURIN_BOUNDS['max_lat'] - TURIN_BOUNDS['min_lat']
    lon_range = TURIN_BOUNDS['max_lon'] - TURIN_BOUNDS['min_lon']
    
    # Estimate number of parkings needed
    avg_size_deg_lat, avg_size_deg_lon = meters_to_degrees(
        PARKING_CONFIG['avg_size_meters'], 
        (TURIN_BOUNDS['min_lat'] + TURIN_BOUNDS['max_lat']) / 2
    )
    
    grid_lat_steps = int(lat_range / (avg_size_deg_lat * 2))
    grid_lon_steps = int(lon_range / (avg_size_deg_lon * 2))
    
    parking_id = 1
    
    for i in range(grid_lat_steps):
        for j in range(grid_lon_steps):
            # Random coverage - not every grid cell has parking
            if random.random() > PARKING_CONFIG['coverage']:
                continue
            
            # Calculate center point with some randomness
            center_lat = TURIN_BOUNDS['min_lat'] + (i + random.uniform(0.3, 0.7)) * (lat_range / grid_lat_steps)
            center_lon = TURIN_BOUNDS['min_lon'] + (j + random.uniform(0.3, 0.7)) * (lon_range / grid_lon_steps)
            
            # Random size variation
            size = PARKING_CONFIG['avg_size_meters'] * random.uniform(
                1 - PARKING_CONFIG['size_variation'],
                1 + PARKING_CONFIG['size_variation']
            )
            
            # Generate polygon
            coords = generate_random_polygon(center_lat, center_lon, size)
            
            # Random parking type
            parking_type = random.choices(
                PARKING_CONFIG['types'],
                weights=PARKING_CONFIG['type_weights']
            )[0]
            
            # Random pricing
            price_range = PRICING[parking_type]
            hourly_rate = round(random.uniform(price_range['min'], price_range['max']), 2)
            
            # Generate capacity based on size
            capacity = int(size / 12) + random.randint(-5, 10)  # ~12m² per spot
            capacity = max(10, capacity)  # Minimum 10 spots
            
            parking = {
                "type": "Feature",
                "properties": {
                    "id": parking_id,
                    "name": f"Parking Zone {parking_id}",
                    "type": parking_type,
                    "hourly_rate": hourly_rate,
                    "capacity": capacity,
                    "available_spots": random.randint(0, capacity),
                    "is_covered": parking_type == 'garage',
                    "has_ev_charging": random.random() < 0.15,  # 15% have EV charging
                    "has_disabled_access": random.random() < 0.3,  # 30% accessible
                    "operating_hours": "24/7" if parking_type in ['garage', 'lot'] else "08:00-20:00"
                },
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [coords]
                }
            }
            
            parkings.append(parking)
            parking_id += 1
    
    return parkings

def main():
    print("Generating Turin parking zones...")
    parkings = generate_parking_grid()
    
    geojson = {
        "type": "FeatureCollection",
        "features": parkings
    }
    
    # Save to file
    output_file = "turin_parkings.geojson"
    with open(output_file, 'w') as f:
        json.dump(geojson, f, indent=2)
    
    print(f"✓ Generated {len(parkings)} parking zones")
    print(f"✓ Saved to {output_file}")
    print(f"\nParking type distribution:")
    for ptype in PARKING_CONFIG['types']:
        count = sum(1 for p in parkings if p['properties']['type'] == ptype)
        print(f"  - {ptype}: {count}")

if __name__ == "__main__":
    main()
