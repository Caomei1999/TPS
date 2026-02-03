"""
One-command script to generate and import Turin parkings
Usage: python setup_parkings.py
"""

import os
import sys

print("="*60)
print("Turin Parkings Setup - Generate & Import")
print("="*60 + "\n")

# Step 1: Generate parkings
print("Step 1: Generating parkings...")
print("-" * 60)
try:
    from generate_turin_parkings import main as generate_parkings
    generate_parkings()
    print()
except Exception as e:
    print(f"✗ Error generating parkings: {e}")
    sys.exit(1)

# Step 2: Import to backend
print("Step 2: Importing to backend...")
print("-" * 60)
try:
    # Import and run the import script
    import import_to_db
    geojson_file = os.path.join(os.path.dirname(__file__), "turin_parkings.geojson")
    
    # Try batch first
    try:
        import_to_db.import_parkings_batch(geojson_file)
    except:
        import_to_db.import_parkings(geojson_file)
    
    print("\n" + "="*60)
    print("✓ Setup Complete! Parkings are now available in your app.")
    print("="*60)
    
except Exception as e:
    print(f"✗ Error importing parkings: {e}")
    sys.exit(1)
