from django.db import models


class NameModel(models.Model):
    """
    기존 테이블(api_name)을 재사용하는 이름(Name) ORM 모델.
    """

    value = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "api_name"
        managed = False
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.value


