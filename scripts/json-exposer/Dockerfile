FROM golang:1.25.5-alpine3.23 AS build
WORKDIR /app
COPY main.go .
RUN go build -o json-exposer main.go

FROM alpine:3.23.2
WORKDIR /app
COPY --from=build /app/json-exposer /app/json-exposer
EXPOSE 8080
ENTRYPOINT ["/app/json-exposer"]

