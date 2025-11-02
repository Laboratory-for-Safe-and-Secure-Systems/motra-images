this directory contains a default postgres installation and a compose file for pgadmin to quickly setup a default container and interact with our database.

oneliners for pgadmin to connect the system to the local network: 

```
docker run -p <hostport>:80 --rm -e 'PGADMIN_DEFAULT_EMAIL=<user@domain.com>' -e 'PGADMIN_DEFAULT_PASSWORD=SuperSecret' <--network=kc_pg-bridge> -d dpage/pgadmin4
```

The hostport parameter is used to interact with the pgadmin web page and to connect the pgadmin container to a database instance.This port configuration is mandatory to access the admin interface. 
The default mail parameter can be changed, but it is mandatory to log into the application.
If using a local network in docker or other containerised setups, the network parameter needs to be added to connect the pgadmin container to the database network.

This oneliner is intened to be used for configuring or checking a local or remote installation for postgres or other supported database systems. After configuration just stop and delete the container. 

