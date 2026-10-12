# Single-node Vespa (Airweave's search index) that deploys Airweave's application
# package itself; upstream compose does that with a separate init container.
# app/ is copied from airweave-ai/airweave vespa/app at the backend's release tag.
FROM vespaengine/vespa:8.754.14
USER root
# Railway mounts the volume empty at /opt/vespa/var (no image content is copied),
# so keep the image's directory skeleton to seed it on first boot.
RUN cp -a /opt/vespa/var /opt/vespa/var.skel
COPY app /opt/airweave-app
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
