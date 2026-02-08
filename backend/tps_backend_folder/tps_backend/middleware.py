from django.shortcuts import redirect
from django.urls import reverse
from django.contrib import messages
from django.contrib.auth import logout  

class SuperUserOnlyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path.startswith('/admin/'):
            login_url = reverse('admin:login')
            logout_url = reverse('admin:logout')
            if request.path.startswith(login_url) or request.path.startswith(logout_url):
                return self.get_response(request)
            if request.user.is_authenticated:
                if not request.user.is_superuser:
                    logout(request)
                    messages.error(request, "Access Denied.")
                    return redirect('admin:login')

        return self.get_response(request)