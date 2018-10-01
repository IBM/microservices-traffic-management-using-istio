FROM openliberty/open-liberty:microProfile1-java8-openj9
ENV SERVERDIRNAME reviews

ADD ./servers/LibertyProjectServer /opt/ol/wlp/usr/servers/defaultServer/

ARG service_version
ARG enable_ratings
ARG star_color
ENV SERVICE_VERSION ${service_version:-v1}
ENV ENABLE_RATINGS ${enable_ratings:-false}
ENV STAR_COLOR ${star_color:-black}

CMD /opt/ol/wlp/bin/server run defaultServer
