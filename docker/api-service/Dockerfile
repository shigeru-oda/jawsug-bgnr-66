FROM python:3.9-slim

WORKDIR /app

# Update system packages to address security vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # Update specific packages with vulnerabilities
    libkrb5-3 \
    libcap2 \
    passwd \
    login \
    openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Expose port for API
EXPOSE 8000

# Run the application
CMD ["python", "main.py"]
