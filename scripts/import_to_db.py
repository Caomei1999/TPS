import json
import requests
import os
from typing import List, Dict

# Backend API configuration - UPDATE THESE
API_CONFIG = {
    'base_url': 'http://localhost:8000',  # Your backend URL
    'admin_email': 'admin@admin.com',   # Admin credentials for authentication
    'admin_password': 'admin'
}

class DjangoAPIClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.csrf_token = None
    
    def get_csrf_token(self) -> str:
        """Get CSRF token from Django"""
        response = self.session.get(f"{self.base_url}/")
        if 'csrftoken' in self.session.cookies:
            return self.session.cookies['csrftoken']
        # Try to extract from response headers
        if 'X-CSRFToken' in response.cookies:
            return response.cookies['X-CSRFToken']
        return None
    
    def login(self, email: str, password: str) -> bool:
        """Authenticate with Django backend"""
        # Get CSRF token first
        self.csrf_token = self.get_csrf_token()
        
        login_url = f"{self.base_url}/auth/login/"
        
        headers = {
            'Content-Type': 'application/json',
            'Referer': self.base_url
        }
        
        if self.csrf_token:
            headers['X-CSRFToken'] = self.csrf_token
        
        data = {
            'email': email,
            'password': password
        }
        
        response = self.session.post(login_url, json=data, headers=headers)
        
        if response.status_code == 200:
            print("✓ Authenticated successfully")
            # Update CSRF token after login
            if 'csrftoken' in self.session.cookies:
                self.csrf_token = self.session.cookies['csrftoken']
            return True
        else:
            print(f"✗ Authentication failed: {response.status_code}")
            print(f"Response: {response.text[:500]}")
            return False
    
    def create_parking(self, parking_data: Dict) -> bool:
        """Create a single parking via API"""
        create_url = f"{self.base_url}/api/parkings/"
        
        headers = {
            'Content-Type': 'application/json',
            'Referer': self.base_url
        }
        
        if self.csrf_token:
            headers['X-CSRFToken'] = self.csrf_token
        
        # Transform GeoJSON to API format
        props = parking_data['properties']
        geometry = parking_data['geometry']
        
        payload = {
            'name': props['name'],
            'parking_type': props['type'],
            'hourly_rate': str(props['hourly_rate']),
            'capacity': props['capacity'],
            'available_spots': props['available_spots'],
            'is_covered': props['is_covered'],
            'has_ev_charging': props['has_ev_charging'],
            'has_disabled_access': props['has_disabled_access'],
            'operating_hours': props['operating_hours'],
            'polygon': geometry['coordinates'][0]  # Send polygon coordinates
        }
        
        response = self.session.post(create_url, json=payload, headers=headers)
        
        return response.status_code in [200, 201]
    
    def create_parkings_batch(self, parkings_data: List[Dict]) -> bool:
        """Create multiple parkings in one request"""
        batch_url = f"{self.base_url}/api/parkings/batch/"
        
        headers = {
            'Content-Type': 'application/json',
            'Referer': self.base_url
        }
        
        if self.csrf_token:
            headers['X-CSRFToken'] = self.csrf_token
        
        batch_payload = []
        for parking in parkings_data:
            props = parking['properties']
            geometry = parking['geometry']
            
            batch_payload.append({
                'name': props['name'],
                'parking_type': props['type'],
                'hourly_rate': str(props['hourly_rate']),
                'capacity': props['capacity'],
                'available_spots': props['available_spots'],
                'is_covered': props['is_covered'],
                'has_ev_charging': props['has_ev_charging'],
                'has_disabled_access': props['has_disabled_access'],
                'operating_hours': props['operating_hours'],
                'polygon': geometry['coordinates'][0]
            })
        
        response = self.session.post(batch_url, json={'parkings': batch_payload}, headers=headers)
        
        return response.status_code in [200, 201]

def import_parkings(geojson_file: str):
    """Import parkings from GeoJSON to backend via API"""
    
    # Load GeoJSON
    print(f"Loading parkings from {geojson_file}...")
    with open(geojson_file, 'r') as f:
        data = json.load(f)
    
    parkings = data['features']
    total = len(parkings)
    print(f"Found {total} parkings to import")
    
    # Create API client and authenticate
    client = DjangoAPIClient(API_CONFIG['base_url'])
    
    if not client.login(API_CONFIG['admin_email'], API_CONFIG['admin_password']):
        print("✗ Failed to authenticate. Aborting import.")
        return
    
    # Import parkings
    success_count = 0
    failed_count = 0
    
    print("\nImporting parkings...")
    for i, parking in enumerate(parkings, 1):
        try:
            if client.create_parking(parking):
                success_count += 1
                if i % 10 == 0:  # Progress update every 10 parkings
                    print(f"  Progress: {i}/{total} ({success_count} successful)")
            else:
                failed_count += 1
                if failed_count <= 3:  # Show first few errors
                    print(f"  ✗ Failed to create parking {parking['properties']['name']}")
        except Exception as e:
            failed_count += 1
            if failed_count <= 3:
                print(f"  ✗ Error creating parking {parking['properties']['name']}: {e}")
    
    print(f"\n{'='*50}")
    print(f"Import completed!")
    print(f"✓ Successfully imported: {success_count}/{total}")
    if failed_count > 0:
        print(f"✗ Failed: {failed_count}/{total}")
    print(f"{'='*50}")

def import_parkings_batch(geojson_file: str):
    """Import parkings in batches (if your API supports batch creation)"""
    
    # Load GeoJSON
    print(f"Loading parkings from {geojson_file}...")
    with open(geojson_file, 'r') as f:
        data = json.load(f)
    
    parkings = data['features']
    total = len(parkings)
    print(f"Found {total} parkings to import")
    
    # Create API client and authenticate
    client = DjangoAPIClient(API_CONFIG['base_url'])
    
    if not client.login(API_CONFIG['admin_email'], API_CONFIG['admin_password']):
        print("✗ Failed to authenticate. Aborting import.")
        return
    
    print("\nSending batch request...")
    if client.create_parkings_batch(parkings):
        print(f"✓ Successfully imported all {total} parkings in batch!")
    else:
        print(f"✗ Batch import failed. Falling back to individual imports...")
        import_parkings(geojson_file)

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    geojson_file = os.path.join(script_dir, "turin_parkings.geojson")
    
    print("Turin Parkings Importer")
    print("="*50)
    print(f"Backend: {API_CONFIG['base_url']}")
    print(f"Using: {geojson_file}")
    print("="*50 + "\n")
    
    # Check if GeoJSON file exists
    if not os.path.exists(geojson_file):
        print("✗ Error: GeoJSON file not found!")
        print("Please run 'python generate_turin_parkings.py' first.")
        exit(1)
    
    # Try batch import first (faster), fall back to individual if not supported
    try:
        import_parkings_batch(geojson_file)
    except Exception as e:
        print(f"Batch import error: {e}")
        # If batch endpoint doesn't exist, import one by one
        import_parkings(geojson_file)
