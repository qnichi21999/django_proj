from django.urls import path

from app import views

urlpatterns = [
    path("", views.index, name="index"),
    path("like/<int:pk>/", views.like, name="like"),
    path("health/", views.health, name="health"),
    path("api/messages/", views.api_messages, name="api_messages"),
]
