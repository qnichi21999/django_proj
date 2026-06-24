from django.db.models import F
from django.http import JsonResponse
from django.shortcuts import redirect, render

from app.models import Message


def index(request):
    if request.method == "POST":
        name = (request.POST.get("name") or "anon").strip()[:50]
        text = (request.POST.get("text") or "").strip()[:280]
        if text:
            Message.objects.create(name=name or "anon", text=text)
        return redirect("index")

    messages = Message.objects.all()[:50]
    return render(request, "index.html", {"messages": messages})


def like(request, pk):
    Message.objects.filter(pk=pk).update(likes=F("likes") + 1)
    return redirect("index")


def health(request):
    return JsonResponse({"status": "healthy"})


def api_messages(request):
    data = list(Message.objects.values("id", "name", "text", "likes", "created_at"))
    return JsonResponse({"count": len(data), "messages": data}, json_dumps_params={"default": str})
