# makes sure openmediavault doesn't attempt to install backported kernals... Can lead to big issues
```bash
sudo nano /etc/apt/preferences.d/no-backports
```

# paste the following contents
```bash
Package: linux-image-*
Pin: release a=stable
Pin-Priority: 1001
```