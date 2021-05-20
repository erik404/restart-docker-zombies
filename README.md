# restart-docker-zombies

Make file executable with `chmod +x restart-docker-zombies.sh`

Script has 2 flags
- `-l` is required and is the limit in minutes a container may exist. If a container exceeds this limit it will be restarted.
- `-e` is optional and can be passed to exclude containers from restarting. Names must be passed space seperated and surrounded by doublequotes.
  
eg:

`./restart-docker-zombies.sh -l 15 -e "redis rabbitmq mongodb"`
