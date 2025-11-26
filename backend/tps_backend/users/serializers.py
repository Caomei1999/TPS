from rest_framework import serializers
from .models import CustomUser
from django.contrib.auth.password_validation import validate_password
from django.core import exceptions

class UserSerializer(serializers.ModelSerializer):
    """
    Serializer used to represent the user's data (e.g., in profile views).
    Excludes password.
    """
    class Meta:
        model = CustomUser
        fields = (
            'id', 
            'email', 
            'first_name', 
            'last_name', 
            'role', 
            'date_joined',
        )
        read_only_fields = ('id', 'email', 'role', 'date_joined')

class UserRegisterSerializer(serializers.ModelSerializer):
    """
    Serializer used for user registration (POST requests).
    It ensures password validation and hashing.
    """
    password = serializers.CharField(write_only=True, required=True)
    
    
    class Meta:
        model = CustomUser
        fields = (
            'email', 
            'first_name', 
            'last_name', 
            'password', 
        )
        extra_kwargs = {'first_name': {'required': True}, 'last_name': {'required': True}}

    def validate(self, data):
        # RIMOSSO: Controllo password match (non serve più)
        
        # Check password strength
        try:
            # Passiamo un'istanza temporanea user per validazioni che dipendono dai dati utente (es. non contenere il nome)
            validate_password(data['password'], user=CustomUser(**data))
        except exceptions.ValidationError as e:
            raise serializers.ValidationError({"password": list(e.messages)})
        
        return data

    def create(self, validated_data):

        validated_data['role'] = 'user'

        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data['role'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
        )
        return user