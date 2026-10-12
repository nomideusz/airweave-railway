# Airweave's web app (static build from the official frontend image) behind Caddy,
# which also proxies /api to the backend and puts a password in front of both.
# Bump the frontend tag together with the backend image tag in the template.
FROM ghcr.io/airweave-ai/airweave-frontend:v0.9.73 AS frontend

FROM caddy:2.11.7-alpine
COPY --from=frontend /app/dist /srv
# The frontend reads its API URL from window.ENV (upstream writes it at container start);
# here the API is same-origin under /api and Airweave's own Auth0 login is off.
RUN printf 'window.ENV = { API_URL: "/api", AUTH_ENABLED: false };\n' > /srv/config.js \
 && sed -i 's|</head>|<script src="/config.js"></script></head>|' /srv/index.html \
 && grep -q 'src="/config.js"' /srv/index.html
COPY Caddyfile /etc/caddy/Caddyfile
# Caddy wants a bcrypt hash; derive it from the generated password on every boot.
# No password or API key = no start, so Airweave is never served open by accident.
CMD ["/bin/sh", "-c", ": \"${AIRWEAVE_PASSWORD:?AIRWEAVE_PASSWORD is required}\" \"${AIRWEAVE_API_KEY:?AIRWEAVE_API_KEY is required}\" \"${BACKEND_UPSTREAM:?BACKEND_UPSTREAM is required}\"; AIRWEAVE_PASSWORD_HASH=$(caddy hash-password --plaintext \"$AIRWEAVE_PASSWORD\") && export AIRWEAVE_PASSWORD_HASH && exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"]
