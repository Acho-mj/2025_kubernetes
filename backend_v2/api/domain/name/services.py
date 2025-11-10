from .entities import Name


class NameDomainService:
    """
    이름(Name) 관련 도메인 규칙을 담는 서비스.
    """

    def validate(self, name: Name) -> None:
        """
        이름 엔터티가 비즈니스 규칙에 맞는지 검증한다.
        """
        if not name.value:
            raise ValueError("이름은 비어 있을 수 없습니다.")
        if len(name.value) > 100:
            raise ValueError("이름은 100자를 넘을 수 없습니다.")


