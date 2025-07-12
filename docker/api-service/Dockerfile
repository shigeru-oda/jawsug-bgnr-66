# syntax=docker/dockerfile:1
FROM python:3.13-slim

# Build arguments for metadata
ARG BUILD_DATE
ARG GIT_HASH
ARG VERSION

# Create a non-root user for security
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home appuser

# Set working directory
WORKDIR /app

# Update system packages to address security vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # Essential security packages
    libkrb5-3 \
    libcap2 \
    passwd \
    login \
    openssl \
    ca-certificates && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy and install Python dependencies first (better caching)
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Change ownership of the app directory to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/home/appuser/.local/bin:$PATH"

# Add metadata labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_HASH}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.title="API Service" \
      org.opencontainers.image.description="FastAPI service with FireLens logging" \
      org.opencontainers.image.base.name="python:3.13-slim"

# Expose port for API
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=5)" || exit 1

# Run the application
CMD ["python", "main.py"]
