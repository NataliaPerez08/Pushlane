FROM python:3.13-slim

# Los slim se quedan atras en el snapshot de Debian: apt upgrade cierra los
# CVEs con fix (p.ej. perl-base CVE-2026-13221) que si no, bloquean el gate
# de trivy en el pipeline.
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

USER 65532:65532
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

