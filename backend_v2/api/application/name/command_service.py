from datetime import datetime, timezone

from backend_v2.api.application.name.dto import CreateNameCommand
from backend_v2.api.domain.name.entities import Name
from backend_v2.api.domain.name.repository import NameRepository
from backend_v2.api.domain.name.services import NameDomainService


class NameCommandService:
    """
    이름(Name) 생성 관련 애플리케이션 서비스.
    """

    def __init__(
        self,
        repository: NameRepository,
        domain_service: NameDomainService | None = None,
    ) -> None:
        self.repository = repository
        self.domain_service = domain_service or NameDomainService()

    def create_name(self, command: CreateNameCommand) -> Name:
        """
        이름 생성 커맨드를 처리한다.
        """
        name = Name(
            id=None,
            value=command.value,
            created_at=datetime.now(tz=timezone.utc),
        )
        self.domain_service.validate(name)
        return self.repository.save(name)


