# Use a small base image
FROM alpine:3.20

# Install dependencies
RUN apk --no-cache add ca-certificates wget unzip

# Set Pocketbase version
ARG POCKETBASE_VERSION=0.22.21

# Detect the architecture of the building machine
ARG TARGETARCH

# Set the working directory
WORKDIR /app

# Download and unzip Pocketbase
RUN wget https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip \
    && unzip pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip \
    && rm pocketbase_${POCKETBASE_VERSION}_linux_${TARGETARCH}.zip

# Make the binary executable
RUN chmod +x /app/pocketbase

# Expose the default Pocketbase port
EXPOSE 8090

# Run Pocketbase
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8090"]
