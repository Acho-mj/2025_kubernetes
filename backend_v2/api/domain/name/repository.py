from abc import ABC, abstractmethod
from typing import List

from .entities import Name


class NameRepository(ABC):
    """
    이름(Name) 엔터티에 대한 저장소 추상화.
    """

    @abstractmethod
    def save(self, name: Name) -> Name:
        """
        이름 엔터티를 저장한다.
        """

    @abstractmethod
    def list(self) -> List[Name]:
        """
        저장된 이름 엔터티 목록을 반환한다.
        """


