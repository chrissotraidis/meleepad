FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY services /app/services

USER 65532:65532
EXPOSE 8765
CMD ["python3", "-m", "services.lobby.server", "--host", "0.0.0.0", "--port", "8765"]
