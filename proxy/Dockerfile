FROM caddy:2-alpine

# utilisateur dédié, pas de root
# setcap -r : sinon caddy réclame une capability qu'on lui retire avec cap_drop ALL
RUN addgroup -S -g 10001 caddy \
 && adduser -S -D -H -u 10001 -G caddy caddy \
 && chown -R caddy:caddy /data /config \
 && setcap -r /usr/bin/caddy

COPY Caddyfile /etc/caddy/Caddyfile

# non-root => ports > 1024
USER caddy
EXPOSE 8080 8443
