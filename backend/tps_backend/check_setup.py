"""
Script to verify Django setup with new user models
Run: python manage.py shell < check_setup.py
"""

print("=" * 60)
print("CHECKING DJANGO SETUP WITH NEW USER MODELS")
print("=" * 60)

# 1. Check user models import
print("\n1. Importing user models...")
try:
    from users.models import Admin, Manager, Patroller, RegularUser
    print("✅ All user models imported successfully")
    print(f"   - Admin: {Admin}")
    print(f"   - Manager: {Manager}")
    print(f"   - Patroller: {Patroller}")
    print(f"   - RegularUser: {RegularUser}")
except Exception as e:
    print(f"❌ Error importing user models: {e}")

# 2. Check parking models
print("\n2. Importing parking models...")
try:
    from parkings.models import City, Parking, Spot
    print("✅ Parking models imported successfully")
except Exception as e:
    print(f"❌ Error importing parking models: {e}")

# 3. Check vehicle models
print("\n3. Importing vehicle models...")
try:
    from vehicles.models import Vehicle, ParkingSession, Violation
    print("✅ Vehicle models imported successfully")
except Exception as e:
    print(f"❌ Error importing vehicle models: {e}")

# 4. Check payment models
print("\n4. Importing payment models...")
try:
    from payments.models import Payment, Wallet
    print("✅ Payment models imported successfully")
except Exception as e:
    print(f"❌ Error importing payment models: {e}")

# 5. Check permissions
print("\n5. Checking permission classes...")
try:
    from users.models import IsAdmin, IsManager, IsPatroller, IsRegularUser
    print("✅ Permission classes imported successfully")
except Exception as e:
    print(f"❌ Error importing permission classes: {e}")

# 6. Check database tables
print("\n6. Checking database tables...")
try:
    from django.db import connection
    tables = connection.introspection.table_names()
    
    expected_tables = [
        'users_admin',
        'users_manager',
        'users_patroller',
        'users_regular',
        'users_patroller_shift',
        'parkings_city',
        'parkings_parking',
        'parkings_spot',
        'vehicles_vehicle',
        'vehicles_parkingsession',
        'vehicles_violation',
        'payments_payment',
        'payments_wallet',
    ]
    
    found = []
    missing = []
    
    for table in expected_tables:
        if table in tables:
            found.append(table)
        else:
            missing.append(table)
    
    print(f"✅ Found {len(found)}/{len(expected_tables)} expected tables")
    
    if missing:
        print(f"\n⚠️  Missing tables (run migrations):")
        for table in missing:
            print(f"   - {table}")
    
except Exception as e:
    print(f"❌ Error checking database: {e}")

# 7. Check AUTH_USER_MODEL setting
print("\n7. Checking AUTH_USER_MODEL setting...")
try:
    from django.conf import settings
    auth_model = settings.AUTH_USER_MODEL
    print(f"✅ AUTH_USER_MODEL: {auth_model}")
    
    if 'users.' not in auth_model:
        print("⚠️  WARNING: AUTH_USER_MODEL should be 'users.Admin', 'users.Manager', etc.")
except Exception as e:
    print(f"❌ Error checking AUTH_USER_MODEL: {e}")

# 8. Test creating instances (if tables exist)
print("\n8. Testing model instantiation...")
try:
    # Test Admin
    admin_test = Admin(admin_id='test_admin')
    print("✅ Admin model instantiation OK")
    
    # Test Manager
    manager_test = Manager(email='test@manager.com', first_name='Test', last_name='Manager')
    print("✅ Manager model instantiation OK")
    
    # Test Patroller
    patroller_test = Patroller(email='test@patroller.com', first_name='Test', last_name='Patroller')
    print("✅ Patroller model instantiation OK")
    
    # Test RegularUser
    user_test = RegularUser(email='test@user.com', first_name='Test', last_name='User')
    print("✅ RegularUser model instantiation OK")
    
except Exception as e:
    print(f"❌ Error instantiating models: {e}")

print("\n" + "=" * 60)
print("SETUP CHECK COMPLETE")
print("=" * 60)
print("\nNext steps:")
print("1. If tables are missing, run: python manage.py makemigrations")
print("2. Then run: python manage.py migrate")
print("3. Create first admin: python manage.py shell")
print("   >>> from users.models import Admin")
print("   >>> admin = Admin.objects.create_superuser(admin_id='admin', password='password')")
print("=" * 60)
