FROM python:3.14-slim

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

# OCI Image Labels
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.title="Big Bear CasaOS User Management" \
      org.opencontainers.image.description="User management web application for CasaOS" \
      org.opencontainers.image.url="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.vendor="BigBearTechWorld" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"

# Run Flask app
CMD ["python", "app.py"]
