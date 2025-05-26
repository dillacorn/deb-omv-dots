this program monitors dockerhub registry and alerts you via email.

to list all containers diun can see (all of them) then run this command

		command:
			docker exec diun diun image list

to update containers:
		command #1: (turn off)
			docker compose down

		command #2: (pull update)
			docker compose pull

		command #3: (relaunch)
			docker compose up -d

you can run commands all at once with &&
    example:
      docker compose down && docker compose pull && docker compose up -d
