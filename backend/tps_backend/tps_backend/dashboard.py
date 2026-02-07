# dashboard.py
from django.utils import timezone
from django.db.models import Sum, Q
from users.models import CustomUser
from vehicles.models import ParkingSession

def dashboard_callback(request, context):
    now = timezone.now()
    today = now.date()
    
    # === 1. User Stats ===
    total_users = CustomUser.objects.count()
    new_users_today = CustomUser.objects.filter(date_joined__date=today).count()
    
    # === 2. Session Stats ===
    active_sessions = ParkingSession.objects.filter(is_active=True).count()
    
    

    all_revenue = ParkingSession.objects.aggregate(sum=Sum('total_cost'))['sum'] or 0
    today_revenue = ParkingSession.objects.filter(start_time__date=today).aggregate(sum=Sum('total_cost'))['sum'] or 0
    
    unpaid_violations = 0 
    new_violations_today = 0
    # unpaid_violations = Fine.objects.filter(status='unpaid').count()
    # new_violations_today = Fine.objects.filter(created_at__date=today).count()

    # === 5. Recent Activity (Latest 5 Users) ===
    recent_activity = CustomUser.objects.order_by('-date_joined')[:5]

    context.update({
        "stats": {
            "total_users": total_users,
            "new_users_today": new_users_today,
            "active_sessions": active_sessions,
            "all_revenue": round(all_revenue, 2),
            "today_revenue": round(today_revenue, 2),
            "unpaid_violations": unpaid_violations,
            "new_violations_today": new_violations_today,
        },
        "recent_activity": recent_activity,
    })
    
    return context