this program monitors dockerhub registry and alerts you via email.

to list all containers diun can see (all of them) then run this command
command:
```bash
docker exec diun diun image list
```

to update containers:

command #1: (turn off)
```bash
docker compose down
```

command #2: (pull update)
```bash
docker compose pull
```

command #3: (relaunch)
```bash
docker compose up -d
```

You can string commands using `&&` between them in the future - for example:
```bash
docker compose down && docker compose pull && docker compose up -d
```
