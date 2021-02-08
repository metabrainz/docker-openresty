# openresty

Openresty + luarocks + lua autossl upon MetaBrainz base image (includes consul-template)

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

## Commit changes, tag and push a new version:

```bash
git add VERSION
git commit -m 'Bump version to vA.B.C.D-E'
git tag $(cat VERSION)
git push origin $(cat VERSION)
make
```

### Push to docker hub

```bash
make docker_push
```

### Push a release to docker hub

```bash
make release
```
