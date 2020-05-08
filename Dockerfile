FROM alpine:latest
MAINTAINER boredazfcuk
# airsonic_version not use. Just change the value to force a rebuild
ARG airsonic_version="10.6.2"
ARG app_dependencies="tzdata ca-certificates openjdk8-jre fontconfig openssl zip ffmpeg flac lame ttf-dejavu mariadb-client wget curl"
ENV config_dir="/config" \
   app_base_dir="/Airsonic"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create directories" && \
   mkdir -p "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install Airsonic" && \
   latest_version="$(curl -sX GET "https://api.github.com/repos/airsonic/airsonic/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]')" && \
   wget -qO "${app_base_dir}/airsonic.war" "https://github.com/airsonic/airsonic/releases/download/${latest_version}/airsonic.war"


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on launcher" && \
   chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${config_dir}"
WORKDIR "${app_base_dir}"

ENTRYPOINT /usr/local/bin/entrypoint.sh