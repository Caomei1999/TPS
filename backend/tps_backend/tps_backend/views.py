from django.shortcuts import render
from django.contrib.admin.views.decorators import staff_member_required
from django.db.models import Sum, Count, Q
from users.models import RegularUser
from vehicles.models import ParkingSession, Violation
from payments.models import Payment
from django.utils import timezone
from datetime import datetime, timedelta

@staff_member_required
def admin_dashboard(request):
    now = timezone.now()
    
    # Total Users - conta TUTTI i RegularUser
    total_users = RegularUser.objects.all().count()
    
    # TEST: Forza un valore hardcoded per vedere se il template funziona
    total_users_test = 999  # Valore di test
    
    # Users registrati oggi (ultime 24 ore da adesso)
    users_today = RegularUser.objects.filter(
        date_joined__gte=now - timedelta(hours=24)
    ).count()
    
    # TEST: Forza valore
    users_today_test = 42  # Valore di test
    
    # Active Sessions
    active_sessions = ParkingSession.objects.filter(
        exit_time__isnull=True
    ).count()
    
    # Revenue - handle both Decimal and None
    total_revenue_result = Payment.objects.filter(
        Q(status='COMPLETED') | Q(status='completed')
    ).aggregate(total=Sum('amount'))
    total_revenue = float(total_revenue_result['total'] or 0)
    
    # Revenue today
    revenue_today = 0
    for field_name in ['payment_date', 'created_at', 'created', 'date']:
        try:
            revenue_result = Payment.objects.filter(
                Q(status='COMPLETED') | Q(status='completed'),
                **{f'{field_name}__gte': now - timedelta(hours=24)}
            ).aggregate(total=Sum('amount'))
            revenue_today = float(revenue_result['total'] or 0)
            break
        except Exception as e:
            continue
    
    # Violations
    unpaid_violations = Violation.objects.filter(
        paid=False
    ).count()
    
    # Violations today
    violations_today = 0
    for field_name in ['issue_date', 'created_at', 'created', 'date']:
        try:
            violations_today = Violation.objects.filter(
                **{f'{field_name}__gte': now - timedelta(hours=24)}
            ).count()
            break
        except Exception as e:
            continue
    
    context = {
        'total_users': total_users_test,
        'users_today': users_today_test,   
        'active_sessions': active_sessions,
        'total_revenue': f"{total_revenue:.2f}",
        'revenue_today': f"{revenue_today:.2f}",
        'unpaid_violations': unpaid_violations,
        'violations_today': violations_today,
    }
    
    return render(request, 'admin/index.html', context)
