import os
import django
from django.utils import timezone
from django.contrib.auth.hashers import make_password

# --- Configure Django ---
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tps_backend.settings")
django.setup()

from users.models import CustomUser

def main():
    now = timezone.now()

    # --- Default passwords by role ---
    DEFAULT_PASSWORDS = {
        "user": "1234",
        "controller": "1234",
        "manager": "1234",
    }

    # --- User type options ---
    user_types = {
        "1": {"role": "user", "prefix": "Customer", "email_domain": "customer.TPS.com"},
        "2": {"role": "controller", "prefix": "Controller", "email_domain": "controller.TPS.com"},
        "3": {"role": "manager", "prefix": "Manager", "email_domain": "manager.TPS.com"},
    }

    print("Select the type of user to create:")
    print("1. Customer")
    print("2. Controller")
    print("3. Manager")
    choice = input("Enter the corresponding number: ").strip()

    if choice not in user_types:
        print("Invalid choice.")
        return

    user_info = user_types[choice]
    role = user_info["role"]
    prefix = user_info["prefix"]
    email_domain = user_info["email_domain"]
    password = DEFAULT_PASSWORDS[role]

    # --- Number of users ---
    try:
        total_users = int(input(f"How many {prefix}s do you want to create? ").strip())
        if total_users <= 0:
            print("Invalid number.")
            return
    except ValueError:
        print("Please enter a valid number.")
        return

    # --- Confirmation ---
    confirm = input(f"Confirm creation of {total_users} {prefix}s? (yes/no): ").strip().lower()
    if confirm != "yes":
        print("Operation cancelled.")
        return

    # --- Batch creation ---
    batch_size = 100
    created = 0
    for start in range(1, total_users + 1, batch_size):
        end = min(start + batch_size - 1, total_users)
        batch_users = []

        for i in range(start, end + 1):
            extra_fields = {}
            if role in ["controller", "manager"]:
                extra_fields["is_staff"] = True

            batch_users.append(
                CustomUser(
                    email=f"{prefix.lower()}{i:05}@{email_domain}",
                    first_name=f"{prefix}{i:05}",
                    last_name="TPS",
                    role=role,
                    password=make_password(password),
                    date_joined=now,
                    **extra_fields
                )
            )

        CustomUser.objects.bulk_create(batch_users)
        created += len(batch_users)
        print(f"Created batch {start}-{end} ({created}/{total_users})")

    print(f"Operation completed: {created} users created with role '{role}'.")

if __name__ == "__main__":
    main()
