from rest_framework import serializers


class NameSerializer(serializers.Serializer):
    """
    이름(Name) 엔터티 직렬화/역직렬화를 담당하는 Serializer.
    """

    id = serializers.IntegerField(read_only=True)
    value = serializers.CharField(max_length=100)
    created_at = serializers.DateTimeField(read_only=True)


