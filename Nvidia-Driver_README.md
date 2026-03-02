# NVIDIA Driver Installation

## single command

```bash
sudo apt update && sudo apt install -y dkms build-essential "linux-headers-$(uname -r)" firmware-misc-nonfree nvidia-driver nvidia-smi
```

reboot & done