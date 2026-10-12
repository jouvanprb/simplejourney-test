# Build Stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
# Statically link binary and inject version
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.version=${VERSION}" -o server .

# Final Stage
FROM scratch
WORKDIR /
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]