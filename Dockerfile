FROM metabrainz/consul-template-base:v0.18.5-2

MAINTAINER Laurent Monin <zas@metabrainz.org>

# Openresty & libs versions
#  https://openresty.org/en/download.html
ARG RESTY_VERSION="1.15.8.2"
#  https://www.openssl.org/source/
ARG RESTY_OPENSSL_VERSION="1.0.2t"
#  http://www.pcre.org/
ARG RESTY_PCRE_VERSION="8.43"

# luarocks & rocks versions
#  https://github.com/luarocks/luarocks/wiki/Download
ARG RESTY_LUAROCKS_VERSION="3.2.1"
#  https://luarocks.org/modules/gui/lua-resty-auto-ssl
ARG RESTY_AUTOSSL_VERSION="0.12.0-1"

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/metabrainz/docker-openresty" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation" \
      org.metabrainz.based-on-image="metabrainz/consul-template-base:v0.18.5-2" \
      org.metabrainz.openresty.version="1.15.8.2"


# build setup
ARG RESTY_J="1"
ARG RESTY_BUILDIR="/tmp/build"
ARG RESTY_CONFIG_OPTIONS="\
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--group=nginx \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-log-path=/var/log/nginx/access.log \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--lock-path=/var/run/nginx.lock \
--modules-path=/usr/lib/nginx/modules \
--pid-path=/var/run/nginx.pid \
--prefix=/usr/local/openresty \
--sbin-path=/usr/local/sbin/openresty \
--user=nginx \
--with-debug \
--with-file-aio \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_geoip_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_realip_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_v2_module \
--with-ipv6 \
--with-luajit-xcflags=-DLUAJIT_ENABLE_LUA52COMPAT \
--with-md5-asm \
--with-pcre-jit \
--with-sha1-asm \
--with-stream \
--with-stream_ssl_module \
--with-threads \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=${RESTY_BUILDIR}/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=${RESTY_BUILDIR}/pcre-${RESTY_PCRE_VERSION}"

RUN apt-get update \
	&& apt-get install --no-install-suggests -y build-essential libssl-dev libgeoip-dev unzip curl wget \
	&& apt-get upgrade -y -o Dpkg::Options::="--force-confold"

RUN adduser --system --no-create-home --disabled-login --disabled-password --group nginx

RUN mkdir -p ${RESTY_BUILDIR}

RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz

RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz

RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
	&& tar xzf openresty-${RESTY_VERSION}.tar.gz

RUN cd ${RESTY_BUILDIR}/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install

RUN mkdir -p /var/cache/nginx/ && chown nginx:nginx /var/cache/nginx/

RUN cd ${RESTY_BUILDIR} \
	&& curl -fkSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
	&& tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz

RUN cd ${RESTY_BUILDIR}/luarocks-${RESTY_LUAROCKS_VERSION} \
	&& ./configure \
		--prefix=/usr/local/openresty/luajit \
		--with-lua=/usr/local/openresty/luajit/ \
		--lua-suffix=jit \
		--with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
	&& make \
	&& make install \
	&& ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
	&& ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
	&& ln -s /usr/local/openresty/luajit/bin/luarocks /usr/local/bin/luarocks

RUN luarocks install lua-resty-auto-ssl ${RESTY_AUTOSSL_VERSION}
RUN mkdir -p /etc/resty-auto-ssl && chown nginx:nginx /etc/resty-auto-ssl

RUN openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/CN=sni-support-required-for-valid-ssl' -keyout /etc/ssl/resty-auto-ssl-fallback.key -out /etc/ssl/resty-auto-ssl-fallback.crt

COPY nginx.conf /etc/nginx/nginx.conf

ADD files/openresty-runit /etc/service/openresty/run

RUN rm -rf ${RESTY_BUILDIR}

RUN mkdir -p /var/log/nginx

RUN apt remove -y `apt list --installed 2>/dev/null|grep -e '^[^/]\+-\(dev\|doc\)/' -e '^gcc' -e '^cpp' -e '^g++' |cut -d '/' -f1|grep -v -- '-base$'`
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /core

EXPOSE 80 443
