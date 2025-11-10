from dataclasses import dataclass


@dataclass
class CreateNameCommand:
    """
    이름 생성 요청을 표현하는 커맨드 DTO.
    """

    value: str


