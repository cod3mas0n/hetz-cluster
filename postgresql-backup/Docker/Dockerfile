FROM python:3.13-slim

RUN apt-get update && apt-get install -y gnupg git curl zip s3cmd ca-certificates postgresql-common vim tmux \
    && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
    && apt install -y postgresql-client-17 \
    && mkdir -p /backup/postgres

WORKDIR /backup

COPY ./postgres-backup.sh /backup/postgres-backup.sh
RUN chmod +x /backup/postgres-backup.sh

ENTRYPOINT ["/backup/postgres-backup.sh"]
