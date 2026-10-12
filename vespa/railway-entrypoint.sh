#!/bin/bash
# Seed and own the volume as root, then run Vespa as the vespa user like the stock
# image does, and (re)deploy Airweave's schemas once the config server answers.
set -eu
VAR=/opt/vespa/var

if [ "$(id -u)" = 0 ]; then
  [ -d "$VAR/db" ] || cp -a /opt/vespa/var.skel/. "$VAR/"
  chown vespa:vespa "$VAR"
  exec setpriv --reuid=vespa --regid=vespa --init-groups "$0" "$@"
fi

# Railway's hostname is random. Pin Vespa's own name and its config server to
# localhost so they match each other and the single-node hosts.xml.
export VESPA_HOSTNAME=localhost VESPA_CONFIGSERVERS=localhost

(
  # Schemas carry the embedding size; it must match the backend's EMBEDDING_DIMENSIONS.
  dim="${EMBEDDING_DIMENSIONS:-1536}"
  app=/tmp/airweave-app
  rm -rf "$app" && cp -r /opt/airweave-app "$app"
  sed -i "s/{{EMBEDDING_DIM}}/$dim/g" "$app"/schemas/*.sd
  sed -i "s/{{VERSION}}/${AIRWEAVE_VERSION:-railway}/g" "$app/services.xml"
  until curl -sf http://localhost:19071/state/v1/health | grep -q '"up"'; do sleep 3; done
  for i in $(seq 20); do
    if vespa-deploy prepare "$app" && vespa-deploy activate; then
      echo "Airweave application package deployed (EMBEDDING_DIMENSIONS=$dim)"
      exit 0
    fi
    echo "deploy attempt $i failed, retrying" >&2
    sleep 10
  done
  echo "Airweave application package deploy FAILED" >&2
) &

exec /usr/local/bin/start-container.sh
