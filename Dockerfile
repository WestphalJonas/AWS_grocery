FROM python:3.13-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app/backend

# Install deps into .venv (cached layer)
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen --no-dev

# Activate venv for all subsequent commands and runtime
ENV PATH="/app/backend/.venv/bin:$PATH"

# Copy backend source
COPY backend/ .

# Create logs dir (frontend/build created by fetch_frontend on startup)
RUN mkdir -p /app/backend/logs

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 5001

CMD ["/docker-entrypoint.sh"]
