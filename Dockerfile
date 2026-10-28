FROM python:3.13-slim
WORKDIR /srv
COPY app/ app/
EXPOSE 5000
CMD ["python", "-m", "app.app"]
