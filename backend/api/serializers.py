from rest_framework import serializers
from .models import Name


class NameSerializer(serializers.ModelSerializer):
    class Meta:
        model = Name
        fields = ['id', 'name', 'created_at']
        read_only_fields = ['id', 'created_at']

