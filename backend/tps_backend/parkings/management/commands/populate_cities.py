from django.core.management.base import BaseCommand
from parkings.models import City

class Command(BaseCommand):
    help = 'Populate initial cities'

    def handle(self, *args, **kwargs):
        cities = [
            ('Milano', 'Italy'),
            ('Roma', 'Italy'),
            ('Torino', 'Italy'),
            ('Napoli', 'Italy'),
            ('Firenze', 'Italy'),
            ('Bologna', 'Italy'),
            ('Venezia', 'Italy'),
            ('Genova', 'Italy'),
            ('Palermo', 'Italy'),
        ]
        
        created_count = 0
        for city_name, country in cities:
            city, created = City.objects.get_or_create(
                name=city_name, 
                defaults={'country': country}
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Created city: {city_name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'○ City already exists: {city_name}')
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'\n✓ Process complete: {created_count} new cities, {len(cities) - created_count} existing')
        )
