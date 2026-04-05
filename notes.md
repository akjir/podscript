Missing Indices.

```shell
podman exec -it -u 33 next-app /var/www/html/occ db:add-missing-indices
```

One or more mimetype migrations are available.

```shell
podman exec -it -u 33 next-app /var/www/html/occ maintenance:repair --include-expensive
```