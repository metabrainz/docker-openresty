FROM metabrainz/consul-template-base:v0.18.5-2

MAINTAINER Laurent Monin <zas@metabrainz.org>

# Openresty & libs versions
# See also https://github.com/openresty/docker-openresty/blob/master/bionic/Dockerfile

#  https://openresty.org/en/download.html
ARG RESTY_VERSION="1.19.3.1"
#  https://www.openssl.org/source/
ARG RESTY_OPENSSL_VERSION="1.1.1i"
# patches to openssl by openresty team, see https://github.com/openresty/openresty/tree/master/patches
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
#  http://www.pcre.org/
ARG RESTY_PCRE_VERSION="8.44"

# luarocks & rocks versions
#  https://github.com/luarocks/luarocks/wiki/Download
ARG RESTY_LUAROCKS_VERSION="3.5.0"
#  https://luarocks.org/modules/gui/lua-resty-auto-ssl
ARG RESTY_AUTOSSL_VERSION="0.13.1-1"

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/metabrainz/docker-openresty" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.vendor="MetaBrainz Foundation" \
      org.metabrainz.based-on-image="metabrainz/consul-template-base:v0.18.5-2" \
      org.metabrainz.openresty.version="1.19.3.1"


# build setup
ARG RESTY_J="1"
ARG RESTY_BUILDIR="/tmp/build"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    "
ARG RESTY_CONFIG_OPTIONS_MORE="--user=nginx --group=nginx"
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_PATHS_CONFIG_OPTIONS="\
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
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
"

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=${RESTY_BUILDIR}/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=${RESTY_BUILDIR}/pcre-${RESTY_PCRE_VERSION}"

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        gettext-base \
        libgd-dev \
        libgeoip-dev \
        libncurses5-dev \
        libperl-dev \
        libreadline-dev \
        libxslt1-dev \
        make \
        perl \
        unzip \
        zlib1g-dev \
    && DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y -o Dpkg::Options::="--force-confold"

RUN adduser --system --no-create-home --disabled-login --disabled-password --group nginx

RUN mkdir -p ${RESTY_BUILDIR}

# openssl building
RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && cd openssl-${RESTY_OPENSSL_VERSION} \
    && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ] ; then \
        echo 'patching OpenSSL 1.1.1 for OpenResty' \
        && curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; \
    fi \
    && ./config \
      no-threads shared zlib -g \
      enable-ssl3 enable-ssl3-method \
      --prefix=/usr/local/openresty/openssl \
      --libdir=lib \
      -Wl,-rpath,/usr/local/openresty/openssl/lib \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install_sw

# pcre building
RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && cd pcre-${RESTY_PCRE_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/pcre \
        --disable-cpp \
        --enable-jit \
        --enable-utf \
        --enable-unicode-properties \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install

# openresty building
RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd ${RESTY_BUILDIR}/openresty-${RESTY_VERSION} \
    && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} ${RESTY_PATHS_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install

# luarocks building
RUN cd ${RESTY_BUILDIR} \
    && curl -fkSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd ${RESTY_BUILDIR}/luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit/ \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make \
    && make install \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/luajit \
    && ln -s /usr/local/openresty/luajit/bin/luajit /usr/local/bin/lua \
    && ln -s /usr/local/openresty/luajit/bin/luarocks /usr/local/bin/luarocks

RUN mkdir -p /etc/resty-auto-ssl && chown nginx:nginx /etc/resty-auto-ssl
RUN mkdir -p /var/cache/nginx/ && chown nginx:nginx /var/cache/nginx/

RUN luarocks install lua-resty-auto-ssl ${RESTY_AUTOSSL_VERSION} \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/CN=sni-support-required-for-valid-ssl' -keyout /etc/ssl/resty-auto-ssl-fallback.key -out /etc/ssl/resty-auto-ssl-fallback.crt

COPY nginx.conf /etc/nginx/nginx.conf

ADD files/openresty-runit /etc/service/openresty/run

RUN rm -rf ${RESTY_BUILDIR}

RUN mkdir -p /var/log/nginx

RUN DEBIAN_FRONTEND=noninteractive apt-mark manual geoip-database libgeoip1 \
    && DEBIAN_FRONTEND=noninteractive apt autoremove -y \
    && DEBIAN_FRONTEND=noninteractive apt remove -y `apt list --installed 2>/dev/null|grep -e '^[^/]\+-\(dev\|doc\)/' -e '^gcc' -e '^cpp' -e '^g++' |cut -d '/' -f1|grep -v -- '-base$'` \
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /core

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

EXPOSE 80 443

# vim: ts=4 ss=4 sw=4 et:
