docker build -t registry.whatever.com/devops/generic/json-exposer:1.0.x .

Sample usage example:

  autodoc:
    image: json-exposer:1.0.x
    container_name: autodoc
    restart: unless-stopped
    expose:
      - "8080"
    volumes:
      - /a-directory-containing-json-files:/app/confs:ro
    networks:
      - monitoring