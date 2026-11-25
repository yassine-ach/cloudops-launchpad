FROM python:3.13-slim
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip uninstall -y pip
COPY app.py .
RUN useradd --create-home appuser
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]