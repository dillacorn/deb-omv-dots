# Prevent OpenMediaVault from Installing Backported Kernels

To avoid potential issues, prevent OpenMediaVault from installing kernel packages from the backports repository.

## Step 1: Create the preferences file

Open the preferences file in a text editor:

```bash
sudo nano /etc/apt/preferences.d/no-kernal-backports
```

## Step 2: Add the following content

Paste the following lines into the file:

```bash
Package: linux-image-*
Pin: release a=stable-backports
Pin-Priority: -1

Package: linux-headers-*
Pin: release a=stable-backports
Pin-Priority: -1

Package: linux-base
Pin: release a=stable-backports
Pin-Priority: -1
```

## Step 3: Save and Exit

- Press `Ctrl + O` to save the file  
- Press `Enter` to confirm  
- Press `Ctrl + X` to exit the editor

This configuration tells APT to avoid installing backported kernel packages by assigning them a negative priority.
