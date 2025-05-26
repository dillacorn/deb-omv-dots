I suggest running docker in linux or with WSL2 on windows and/or virtualbox.
I suggest running your containers on an SSD to reduce strain on your hard drives... primarily for extend the life of the hard drives.
I suggest doing a backup of your "docker" folder to a docker folder on your hard drives + a backup rsync schedule to a similar sized hard drive. (3 backups)

rsync commands: (or if you're on openmediavault setup shares of the docker container on your SSD and your HDD and schedule regular backups)

	command #1: (this command does an rsync copy to a location with monitoring and without deleting files/folders on receiving end)
		rsync -avh --progress /source/path/ /destination/path/
	command #2: (this command does an rsync copy to a location with monitoring and deletes files/folders on the receing end)
		rsync -avh --progress --delete --info=progress2 /source/path/ /destination/path/

docker-compose_example.yml = modification is required for use
docker-compose.yml = modification is not required

to start a docker application cmd/TTY to folder location with compose .yml file in location.

run container command = docker compose up -d
stop container command = docker stop *container_name* (without the *)

to see container name for the docker application please read the docker-compose.yml

good luck... dm me if you have issue.



docker commands I know and use:

docker compose pull                        (pulls the latest update for the container)
docker rm <container_name>                 (for removing volumes)
docker compose up -d                       (starts container)
docker logs <container_name>               (view containers running logs)
docker compose down                        (stops container while cd into directory)
docker stop <container_name>               (stopping a specific container from anywhere)
docker volume prune                        (removed unused volumes ~ be mindful when doing this.. [you will recieve a warning] unless if all your containers are storing data in there own respective folders then you'll be ok.)
docker volume ls                           (lists volumes)
docker volume inspect <volume_name>        (inspect a volume)
docker ps                                  (list running containers)
docker ps -a                               (list all containers)
