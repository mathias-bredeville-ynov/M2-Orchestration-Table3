FROM hashicorp/vault:latest

USER root

COPY agent.hcl /vault/config/agent.hcl
COPY templates /vault/templates
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && mkdir -p /vault/auth /vault/secrets

ENTRYPOINT ["/entrypoint.sh"]
