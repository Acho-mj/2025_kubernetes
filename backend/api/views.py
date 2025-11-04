from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from django.db import connection
from .models import Name
from .serializers import NameSerializer
import traceback


@api_view(['GET'])
def health_check(request):
    """서버 상태 확인"""
    try:
        # 데이터베이스 연결 테스트
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        # 테이블 존재 확인
        table_exists = False
        try:
            Name.objects.all().count()
            table_exists = True
        except Exception:
            pass
        
        return Response({
            'status': 'ok',
            'database': 'connected',
            'table_exists': table_exists
        })
    except Exception as e:
        return Response({
            'status': 'error',
            'error': str(e),
            'traceback': traceback.format_exc()
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class NameViewSet(viewsets.ModelViewSet):
    """
    이름 저장 및 조회 API
    
    GET /api/names/ - 이름 목록 조회
    POST /api/names/ - 이름 저장
    """
    queryset = Name.objects.all()
    serializer_class = NameSerializer

    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except Exception as e:
            return Response({
                'error': '목록 조회 실패',
                'detail': str(e),
                'traceback': traceback.format_exc()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def create(self, request, *args, **kwargs):
        try:
            return super().create(request, *args, **kwargs)
        except Exception as e:
            return Response({
                'error': '이름 저장 실패',
                'detail': str(e),
                'traceback': traceback.format_exc()
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

