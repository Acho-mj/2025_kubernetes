from typing import List

from backend_v2.api.domain.name.entities import Name
from backend_v2.api.domain.name.repository import NameRepository


class NameQueryService:
    """
    이름(Name) 조회 애플리케이션 서비스.
    """

    def __init__(self, repository: NameRepository) -> None:
        self.repository = repository

    def list_names(self) -> List[Name]:
        """
        저장된 이름 목록을 반환한다.
        """
        return self.repository.list()


