FROM python:3.12-slim

RUN pip install --no-cache-dir "psycopg[binary]==3.2.*"

WORKDIR /app
COPY events.sql notifier.py ./

CMD ["python3", "-u", "notifier.py"]
