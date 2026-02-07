from django.contrib import admin
from django import forms
from unfold.admin import ModelAdmin
from .models import Vehicle, ParkingSession, Fine
from users.models import CustomUser
from unfold.decorators import display
from django.contrib import messages

class VehicleAdminForm(forms.ModelForm):
    class Meta:
        model = Vehicle
        fields = '__all__'
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['user'].queryset = CustomUser.objects.filter(role='user')

@admin.register(Vehicle)
class VehicleAdmin(ModelAdmin):
    form = VehicleAdminForm
    list_display = ('plate', 'name', 'user', 'is_favorite')
    search_fields = ('plate', 'user__email', 'name')
    list_filter = ('name', 'is_favorite')

@admin.register(ParkingSession)
class ParkingSessionAdmin(ModelAdmin):
    list_display = ('id', 'user', 'vehicle', 'parking_lot', 'start_time', 'is_active', 'total_cost')
    list_filter = ('is_active',)
    search_fields = ('vehicle__plate', 'user__email', 'parking_lot__name')

@admin.action(description="🔄 Reset Owner's Standing (Unban & Zero Count)")
def reset_owner_standing(modeladmin, request, queryset):
    count = 0
    for fine in queryset:
        user = fine.vehicle.user

        if user and (user.violations_count > 0 or not user.is_active):
            user.violations_count = 0
            user.is_active = True
            user.save()
            count += 1
            
    modeladmin.message_user(
        request, 
        f"Successfully reset account standing for {count} users associated with selected fines.", 
        messages.SUCCESS
    )

@admin.register(Fine)
class FineAdmin(ModelAdmin):
    list_display = ('id', 'vehicle_plate', 'vehicle_owner', 'owner_violations', 'amount_display', 'reason', 'status_badge', 'issued_at', 'issued_by')
    
    list_filter = ('status', 'issued_at')

    search_fields = ('vehicle__plate', 'reason', 'id', 'vehicle__user__email')
    
    actions = [reset_owner_standing]
    
    fieldsets = (
        ("Violation Details", {
            "fields": ("vehicle", "session", "issued_by", "reason", "amount")
        }),
        ("Status & Time", {
            "fields": ("status", "issued_at", "paid_at")
        }),
    )

    @display(description="Status", label=True)
    def status_badge(self, obj):
        colors = {
            'unpaid': 'danger',      
            'paid': 'success',       
            'disputed': 'warning',   
            'cancelled': 'secondary',
        }
        return obj.get_status_display(), colors.get(obj.status, 'primary')

    def vehicle_owner(self, obj):
        return obj.vehicle.user.email
    vehicle_owner.short_description = "Owner Account"

    def owner_violations(self, obj):
        return obj.vehicle.user.violations_count
    owner_violations.short_description = "Violations"

    def vehicle_plate(self, obj):
        return obj.vehicle.plate
    vehicle_plate.short_description = "Plate"

    def amount_display(self, obj):
        return f"€ {obj.amount}"
    amount_display.short_description = "Amount"