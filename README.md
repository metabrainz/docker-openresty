# openresty

Openresty + luarocks upon MetaBrainz base image (includes consul-template)

https://hub.docker.com/r/metabrainz/docker-openresty/

# Dependencies

- make
- https://openresty.org/en/download.html
- https://www.openssl.org/source/
- https://github.com/PCRE2Project/pcre2/releases
- https://github.com/luarocks/luarocks/wiki/Download

# Upgrading/building

Update dependency versions in `Dockerfile`:

- `RESTY_VERSION` — OpenResty release
- `RESTY_OPENSSL_VERSION` — OpenSSL version to build
- `RESTY_OPENSSL_PATCH_VERSION` — must match the latest patch available in
  [openresty/openresty/patches/](https://github.com/openresty/openresty/tree/master/patches)
  (e.g. `3.5.5` even if building OpenSSL `3.5.6`)
- `RESTY_PCRE_VERSION` and `RESTY_PCRE_SHA256`
- `RESTY_LUAROCKS_VERSION`
- LABEL `org.metabrainz.openresty.version`

Reference: https://github.com/openresty/docker-openresty/blob/master/noble/Dockerfile

## Test building:

```bash
echo vA.B.C.D-E > VERSION
make
```

## Commit changes, tag and push a new version:

```bash
git add Dockerfile VERSION
git commit -m "Bump version to $(cat VERSION)"
git tag "$(cat VERSION)"
git push origin master "$(cat VERSION)"
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
