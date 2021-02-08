# openresty
Openresty + luarocks + lua autossl

https://hub.docker.com/r/metabrainz/docker-openresty/

# Dependencies

- make
- https://openresty.org/en/download.html
- https://www.openssl.org/source/
- http://www.pcre.org/
- https://github.com/luarocks/luarocks/wiki/Download
- https://luarocks.org/modules/gui/lua-resty-auto-ssl

# Upgrading/building

Update dependencies versions in `Dockerfile`
Don't forget to change version in LABEL `org.metabrainz.openresty.version`

## Test building:

```bash
echo vA.B.C.D-E > VERSION
make
```

## Commit changes and tag version:

```bash
git add VERSION
git commit -m 'Bump version to vA.B.C.D-E'
git tag vA.B.C.D-E
make
```

## Push new version

`git push origin vA.B.C.D-E`
