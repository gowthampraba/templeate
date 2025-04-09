FROM mcr.microsoft.com/dotnet/sdk:8.0
WORKDIR /app
ENV NON_ROOT_USER=devops
ENV NON_ROOT_GID="103" \
    NON_ROOT_UID="1003" \
    NON_ROOT_WORK_DIR=/opt/local/$NON_ROOT_USER \
    NON_ROOT_HOME_DIR=/home/$NON_ROOT_USER
ENV PUBLISH=./ArchKey.PFW.Api/bin/Release/net8.0/publish/

RUN groupadd -g 65532 $NON_ROOT_USER && useradd -m -s /bin/bash -u 65532 $NON_ROOT_USER -g $NON_ROOT_USER

RUN apt-get update \
    && apt-get -y install curl \
    wget \
    unzip \
    jq \
    openssl\
    supervisor

RUN mkdir -p /var/log/supervisor
COPY ./devops/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN wget https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64
RUN mv confd-0.16.0-linux-amd64 /usr/sbin/confd
RUN chmod +x /usr/sbin/confd
RUN mkdir -p /etc/confd
COPY ./devops/confd/ /etc/confd/

RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates fontconfig libc6 libfreetype6 libjpeg62-turbo libpng16-16 libssl3 libstdc++6 libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base zlib1g
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb
RUN dpkg -i wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

COPY --chown=$NON_ROOT_USER:$NON_ROOT_USER $PUBLISH ./

RUN chown -R $NON_ROOT_USER:$NON_ROOT_USER /app
RUN chown -R $NON_ROOT_USER:$NON_ROOT_USER /etc/confd
RUN chown -R $NON_ROOT_USER:$NON_ROOT_USER /etc/supervisor/conf.d
RUN chown -R $NON_ROOT_USER:$NON_ROOT_USER /var/run
RUN chown -R $NON_ROOT_USER:$NON_ROOT_USER /var/log

RUN chmod -R 750 /app
RUN chmod -R 750 /etc/confd
RUN chmod -R 750 /etc/supervisor/conf.d
RUN chmod -R 777 /var/run
RUN chmod -R 777 /var/log

USER $NON_ROOT_USER

CMD ["/usr/bin/supervisord"]
