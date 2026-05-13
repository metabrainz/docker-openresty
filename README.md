# openresty

Openresty + luarocks upon MetaBrainz base image (includes consul-template)

https://hub.docker.com/r/metabrainz/docker-openresty/

# Dependencies

- make
- https://openresty.org/en/download.html
- https://www.openssl.org/source/
- http://www.pcre.org/
- https://github.com/luarocks/luarocks/wiki/Download

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
git commit -m "Bump version to $(cat VERSION)"
git tag "$(cat VERSION)"
git push origin "$(cat VERSION)"
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
