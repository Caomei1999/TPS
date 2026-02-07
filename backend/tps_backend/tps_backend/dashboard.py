from django.utils import timezone
from django.db.models import Sum
from users.models import CustomUser
from vehicles.models import Fine, ParkingSession

def dashboard_callback(request, context):
    now = timezone.now()
    today = now.date()

    # --- STATISTICHE GENERALI ---
    total_users = CustomUser.objects.count()
    new_users_today = CustomUser.objects.filter(date_joined__date=today).count()
    active_sessions = ParkingSession.objects.filter(is_active=True).count()
    
    all_revenue = ParkingSession.objects.aggregate(sum=Sum('total_cost'))['sum'] or 0
    today_revenue = ParkingSession.objects.filter(start_time__date=today).aggregate(sum=Sum('total_cost'))['sum'] or 0
    
    active_violations_count = Fine.objects.exclude(status__in=['paid', 'cancelled']).count()
    pending_disputes = Fine.objects.filter(status='disputed').count()

    # --- ACTIVITY FEED UNIFICATO ---
    activity_feed = []

    # 1. Nuovi Utenti (Tipo: user)
    recent_users = CustomUser.objects.order_by('-date_joined')[:5]
    for user in recent_users:
        activity_feed.append({
            'type': 'user',
            'timestamp': user.date_joined,
            'identifier': user.email,
            'title': 'New User',
            'amount': None,
        })

    # 2. Sessioni Avviate (Tipo: session)
    recent_sessions = ParkingSession.objects.select_related('vehicle').order_by('-start_time')[:5]
    for session in recent_sessions:
        plate = session.vehicle.plate if session.vehicle else "Unknown"
        activity_feed.append({
            'type': 'session',
            'timestamp': session.start_time,
            'identifier': plate,
            'title': 'Session Started',
            'amount': session.total_cost, 
        })

    # 3. Multe Pagate (Tipo: fine_payment)
    recent_paid_fines = Fine.objects.filter(status='paid', paid_at__isnull=False).select_related('vehicle').order_by('-paid_at')[:5]
    for fine in recent_paid_fines:
        plate = fine.vehicle.plate if fine.vehicle else "Unknown"
        activity_feed.append({
            'type': 'fine_payment',
            'timestamp': fine.paid_at,
            'identifier': plate,
            'title': 'Fine Paid',
            'amount': fine.amount,
        })

    # 4. NUOVO: Violazioni Emesse (Tipo: fine_issued)
    recent_issued_fines = Fine.objects.select_related('vehicle').order_by('-issued_at')[:5]
    for fine in recent_issued_fines:
        plate = fine.vehicle.plate if fine.vehicle else "Unknown"
        activity_feed.append({
            'type': 'fine_issued',
            'timestamp': fine.issued_at,
            'identifier': plate,
            'title': 'Violation Issued',
            'amount': fine.amount,
        })

    # 5. Ordina per data (dal più recente) e prendi i primi 8
    activity_feed.sort(key=lambda x: x['timestamp'], reverse=True)
    final_activity = activity_feed[:8]

    context.update({
        "stats": {
            "total_users": total_users,
            "new_users_today": new_users_today,
            "active_sessions": active_sessions,
            "all_revenue": round(all_revenue, 2),
            "today_revenue": round(today_revenue, 2),
            "active_violations_count": active_violations_count,
            "pending_disputes": pending_disputes,
        },
        "recent_activity": final_activity,
    })
    
    return context