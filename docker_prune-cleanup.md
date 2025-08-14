## Docker Disk Prune — Commands to Reclaim Space

Use these single commands to free Docker disk space. Prefer the explicit `-a -f` style.

## Flag glossary and terminology
- `-f`, `--force` → run without confirmation prompt.
- `-a`, `--all` → act on **all** unused objects (not just “dangling”).
  - `docker image prune -a -f` → remove all images not used by any container.
  - `docker builder prune -a -f` → remove all unused build cache entries.
  - `docker system prune -a -f` → also removes all unused images (not only dangling).
- `-v`, `--verbose` (only for `docker system df`) → show per-object detail.
- `--volumes`
  - With `docker system prune` → also remove all **unused** local volumes.
  - With `docker compose down` → remove named volumes from the Compose file and anonymous volumes attached to containers.
- `--rmi local|all` (only for `docker compose down`)
  - `local` → remove images built by the compose project (and unnamed local images).
  - `all` → remove **all** images used by services in the project.
- **Dangling vs Unused**
  - *Dangling images* → untagged (`<none>:<none>`) leftovers; safe to delete.
  - *Unused images* → not used by any container (running or stopped). Includes dangling **and** tagged-but-unused images.

## Show current Docker disk usage (verbose)
```bash
docker system df -v
```
Detailed usage for images, containers, volumes, and build cache (`-v`, `--verbose` shows per-item breakdown).

## Remove dangling (untagged) images only
```bash
docker image prune -f
```
Deletes only untagged images not referenced by any container (`-f`, `--force` skips prompt).

## Remove all unused images
```bash
docker image prune -a -f
```
Deletes every image not used by any container (`-a`, `--all` + `-f`, `--force`).

## Remove stopped containers
```bash
docker container prune -f
```
Deletes all **stopped** containers (`-f`, `--force`).

## Remove unused volumes
```bash
docker volume prune -f
```
Deletes volumes not used by any container. **Persistent data risk**. (`-f`, `--force`).

## Remove unused networks
```bash
docker network prune -f
```
Deletes networks not used by any container (`-f`, `--force`).

## Remove build cache (BuildKit / buildx)
```bash
docker builder prune -a -f
```
Deletes all unused build cache entries (`-a`, `--all`) without prompting (`-f`, `--force`).

## Remove everything unused (broad cleanup)
```bash
docker system prune -a --volumes -f
```
Removes unused containers, networks, images (**all**, not just dangling), and **unused volumes** (`--volumes`). Destructive.

## Per-project cleanup (from the project directory)
```bash
docker compose down --rmi local --volumes
```
Tears down the stack, removes project-built images (`--rmi local`) and both named + anonymous volumes for those services (`--volumes`).

## Truncate oversized container logs (non-destructive)
```bash
sudo find /var/lib/docker/containers -type f -name "*-json.log" -size +100M -exec truncate -s 0 {} \;
```
Resets large JSON logs in-place. For **rootless Docker**, the path is typically `~/.local/share/docker/containers`.
