from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken 
from .serializers import UserRegisterSerializer
from rest_framework.permissions import IsAuthenticated

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

class RegisterUserView(APIView):
    permission_classes = () 
    authentication_classes = ()

    def post(self, request):
        serializer = UserRegisterSerializer(data=request.data)
        if serializer.is_valid():

            user = serializer.save()
            tokens = get_tokens_for_user(user)
            response_data = {
                'message': 'Registration successful.',
                'user': serializer.data, 
                'tokens': tokens
            }
            return Response(response_data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

register_user = RegisterUserView.as_view()

class ProfileView(APIView):
    permission_classes = [IsAuthenticated] 

    def get(self, request):
        user = request.user

        data = {
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'full_name': user.get_full_name(), 
        }
        
        return Response(data, status=status.HTTP_200_OK)
    
profile_view = ProfileView.as_view()