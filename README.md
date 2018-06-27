# openresty
Openresty + luarocks + lua autossl

https://hub.docker.com/r/metabrainz/docker-openresty/

# Dependencies

- https://openresty.org/en/download.html
- https://www.openssl.org/source/
- http://www.pcre.org/
- https://github.com/luarocks/luarocks/wiki/Download
- https://luarocks.org/modules/gui/lua-resty-auto-ssl

# Upgrading/building

Update dependencies versions in `Dockerfile`
Don't forget to change version in LABEL `org.metabrainz.openresty.version`

## Test building:

`docker build -t openresty-vA.B.C.D-E .`

## Commit changes and tag version:

`git tag vA.B.C.D-E`

## Push new version

`git push origin vA.B.C.D-E`
