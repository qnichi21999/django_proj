from django.db import models


class Message(models.Model):
    name = models.CharField(max_length=50, default="anon")
    text = models.CharField(max_length=280)
    likes = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name}: {self.text[:30]}"
