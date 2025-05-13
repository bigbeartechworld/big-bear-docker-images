FROM python:3.13-slim

# Install system dependencies (systemd includes systemctl)
RUN apt-get update && \
    apt-get install -y systemd sudo && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/lib/casaos/db

# Set working directory
WORKDIR /app

# Copy all application files
COPY app/ .

# Install Python dependencies
RUN pip install flask flask-wtf

# Create a volume for persistent storage
VOLUME /var/lib/casaos/db

# Expose port for Flask
EXPOSE 5000

# Run Flask app
CMD ["python", "app.py"]
