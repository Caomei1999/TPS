from django.core.management.base import BaseCommand
from parkings.models import Parking, Spot

class Command(BaseCommand):
    help = 'Popola il database con parcheggi realistici per Roma, Milano, Torino e Bari'

    def handle(self, *args, **options):
        # Lista dati
        parkings_data = [
            # --- ROMA ---
            {
                "name": "Roma Termini - Piazza dei Cinquecento",
                "city": "Roma",
                "address": "Piazza dei Cinquecento, 1",
                "rate": 3.50,
                "lat": 41.9009,
                "lon": 12.5020,
                "spots": 120
            },
            {
                "name": "Parcheggio Villa Borghese",
                "city": "Roma",
                "address": "Viale del Galoppatoio, 33",
                "rate": 2.80,
                "lat": 41.9105,
                "lon": 12.4886,
                "spots": 150
            },
            
            # --- MILANO ---
            {
                "name": "Milano Centrale - Piazza Duca d'Aosta",
                "city": "Milano",
                "address": "Piazza Duca d'Aosta, 1",
                "rate": 4.00,
                "lat": 45.4851,
                "lon": 9.2035,
                "spots": 200
            },
            {
                "name": "Parcheggio Duomo (Rinascente)",
                "city": "Milano",
                "address": "Via Agnello, 10",
                "rate": 5.50,
                "lat": 45.4653,
                "lon": 9.1913,
                "spots": 80
            },

            # --- TORINO (Altri) ---
            {
                "name": "Parcheggio Roma San Carlo",
                "city": "Torino",
                "address": "Piazza Carlo Felice, 14",
                "rate": 3.00,
                "lat": 45.0638,
                "lon": 7.6804,
                "spots": 180
            },
            {
                "name": "Lingotto Parking",
                "city": "Torino",
                "address": "Via Nizza, 280",
                "rate": 2.00,
                "lat": 45.0329,
                "lon": 7.6645,
                "spots": 300
            },

            # --- BARI ---
            {
                "name": "Bari Stazione Centrale",
                "city": "Bari",
                "address": "Piazza Aldo Moro",
                "rate": 1.50,
                "lat": 41.1187,
                "lon": 16.8710,
                "spots": 100
            },
            {
                "name": "Parcheggio Saba Porto",
                "city": "Bari",
                "address": "Corso Antonio de Tullio",
                "rate": 1.80,
                "lat": 41.1320,
                "lon": 16.8675,
                "spots": 110
            }
        ]

        self.stdout.write("--- INIZIO CREAZIONE PARCHEGGI ---")

        for p_data in parkings_data:
            # 1. Crea o ottieni il parcheggio
            parking, created = Parking.objects.get_or_create(
                name=p_data["name"],
                defaults={
                    "city": p_data["city"],
                    "address": p_data["address"],
                    "rate_per_hour": p_data["rate"],
                    "latitude": p_data["lat"],
                    "longitude": p_data["lon"]
                }
            )

            if created:
                self.stdout.write(f"✅ Creato parcheggio: {parking.name} ({parking.city})")
                
                # 2. Genera gli spot
                spots_to_create = []
                for i in range(1, p_data["spots"] + 1):
                    floor = "P-1" if i < 50 else "P-2"
                    zone = "A" if i % 2 != 0 else "B"
                    
                    spots_to_create.append(Spot(
                        parking=parking,
                        number=str(i),
                        floor=floor,
                        zone=zone,
                        is_occupied=False
                    ))
                
                Spot.objects.bulk_create(spots_to_create)
                self.stdout.write(f"   -> Generati {len(spots_to_create)} posti auto.")
                
            else:
                self.stdout.write(self.style.WARNING(f"⚠️  Parcheggio esistente: {parking.name} (Saltato)"))

        self.stdout.write(self.style.SUCCESS("--- OPERAZIONE COMPLETATA ---"))