admin account creation:

docker compose exec synapse register_new_matrix_user \
  --config /data/homeserver.yaml \
  --user username \
  --password 'password' \
  --admin \
  http://synapse:8008

normal user account creation:

docker compose exec synapse register_new_matrix_user \
  --config /data/homeserver.yaml \
  --user username \
  --password 'password' \
  http://synapse:8008

--

## How to access
Your tailscale magicDNS address

example:
https://MACHINE.MagicDNS-example.ts.net