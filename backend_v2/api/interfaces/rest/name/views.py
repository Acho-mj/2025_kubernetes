from rest_framework import status, viewsets
from rest_framework.response import Response

from backend_v2.api.application.name.command_service import NameCommandService
from backend_v2.api.application.name.dto import CreateNameCommand
from backend_v2.api.application.name.query_service import NameQueryService
from backend_v2.api.infrastructure.name.orm_repository import DjangoORMNameRepository
from backend_v2.api.interfaces.rest.name.serializers import NameSerializer


class NameViewSet(viewsets.ViewSet):
    """
    이름(Name) 등록 및 조회 REST 뷰셋.
    """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        repository = DjangoORMNameRepository()
        self.command_service = NameCommandService(repository)
        self.query_service = NameQueryService(repository)

    def list(self, request):
        names = self.query_service.list_names()
        serializer = NameSerializer(names, many=True)
        return Response(serializer.data)

    def create(self, request):
        serializer = NameSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        command = CreateNameCommand(value=serializer.validated_data["value"])
        name = self.command_service.create_name(command)

        response_serializer = NameSerializer(name)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


