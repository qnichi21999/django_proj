from django.test import TestCase
from django.urls import reverse

from app.models import Message


class ViewsTestCase(TestCase):
    def test_index_renders(self):
        response = self.client.get(reverse("index"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Гостевая книга")

    def test_health_returns_healthy(self):
        response = self.client.get(reverse("health"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "healthy")

    def test_post_creates_message(self):
        response = self.client.post(
            reverse("index"), {"name": "tester", "text": "hello world"}
        )
        self.assertRedirects(response, reverse("index"))
        self.assertEqual(Message.objects.count(), 1)
        self.assertEqual(Message.objects.first().text, "hello world")

    def test_empty_text_is_ignored(self):
        self.client.post(reverse("index"), {"name": "tester", "text": "   "})
        self.assertEqual(Message.objects.count(), 0)

    def test_like_increments(self):
        msg = Message.objects.create(name="a", text="x")
        self.client.post(reverse("like", args=[msg.pk]))
        msg.refresh_from_db()
        self.assertEqual(msg.likes, 1)

    def test_api_returns_messages(self):
        Message.objects.create(name="a", text="x")
        response = self.client.get(reverse("api_messages"))
        self.assertEqual(response.json()["count"], 1)
