# makes sure openmediavault doesn't attempt to install backported kernals... Can lead to big issues
```bash
sudo nano /etc/apt/preferences.d/no-backports
```

# paste the following contents
```bash
Package: linux-image-* linux-headers-*
Pin: release a=bookworm-backports
Pin-Priority: -1
```