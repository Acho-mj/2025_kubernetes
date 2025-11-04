from django.db import models


class Name(models.Model):
    """이름 저장 모델"""
    name = models.CharField(max_length=100, verbose_name='이름')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='생성일시')

    class Meta:
        ordering = ['-created_at']
        verbose_name = '이름'
        verbose_name_plural = '이름 목록'

    def __str__(self):
        return self.name

