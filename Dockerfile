# Stage 1: Build the binary with Go
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install build dependencies for CGO / SQLite
RUN apk add --no-cache gcc musl-dev

# Cache Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy source code and build optimized binary
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -ldflags="-s -w" -o /app/bin/gridpulse ./cmd/server

# Stage 2: Minimal runtime image
FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache ca-certificates sqlite-libs

# Create data directory and non-root user with correct permissions for SQLite
RUN mkdir -p /app/data \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /app

USER appuser

COPY --from=builder /app/bin/gridpulse /app/gridpulse

ENV PORT=8080
ENV DB_PATH=/app/data/gridpulse.db

EXPOSE 8080

CMD ["/app/gridpulse"]
