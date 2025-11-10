from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass(frozen=True)
class Name:
    """
    이름(Name) 도메인 엔터티.
    """

    id: Optional[int]
    value: str
    created_at: datetime


