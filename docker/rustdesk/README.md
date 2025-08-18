When you launch container type command to view server key

docker logs hbbs

OR alternatively

cd to /data folder = cd /data

then read "id_ed####.pub" file = cat id_ed####.pub
your .pub key will gave a different string of numbers and letters.

once you got the server key add them to your client machines (don't forget the server IP) and connection should say "Ready" in green.

if it doesn't say ready make sure you're connected in tailscale..if it's a shared server make sure the owner allows ports 21114-21118 in ACL.

see my example ACL configurations for tailscale: https://github.com/dillacorn/tailscale_example_ACL_configs