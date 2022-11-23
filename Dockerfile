FROM debian:bullseye
ARG VERSION_PG=12

RUN apt-get update \
    && apt-get install -y wget gnupg2

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update \
    && apt-get install -y postgresql-client-$VERSION_PG

COPY ./scripts /opt

WORKDIR /opt

RUN mkdir backup-data
# VOLUME ["/opt/backup-data"]


 CMD ["./pg-back.sh"]
