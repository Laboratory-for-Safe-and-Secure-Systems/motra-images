Redis testing instance from docker hub.


## One liners for running a local instance

Start the default instance without any configuration: 

```
docker run --name some-redis -d redis
```

Important here: this instance is not secured and allows passwordless login.
This might not be intended and should not be used in a production environment without proper configuration.

Run redis with persistant storage: 

```
docker run --name some-redis -d redis redis-server --save 60 1 --loglevel warning
```

This may need additional configuration for the used volumes. This configuration writes a copy of the database to the disk every 60 seconds.


## Additional Information

Bitnami also has a very well documented image for a Redis stack: https://hub.docker.com/r/bitnami/redis/

This can also be used to further customize the setup.


A sample compose file should then be used like this: 

```
networks:
  app-tier:
    driver: bridge

services:
  redis:
    image: 'bitnami/redis:latest'
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    networks:
      - app-tier
  myapp:
    image: 'YOUR_APPLICATION_IMAGE'
    networks:
      - app-tier
```

