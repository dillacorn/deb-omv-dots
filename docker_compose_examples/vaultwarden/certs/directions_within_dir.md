## Run inside this directory to get Tailscale certs.
## Make sure HTTPS is enabled in Tailscale admin settings.

```sh
sudo tailscale cert --cert-file=cert.pem --key-file=key.pem your.domain.name
```