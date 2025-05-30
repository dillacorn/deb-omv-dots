# NVIDIA Driver Installation Guide

## Make the NVIDIA driver executable

Run the following command to make the installer executable:

```bash
chmod +x NVIDIA-Linux-x86_64-5xx.1xx.0x.run
```

## Important Notes Before Installation

You do **not** need to install:

- Vulkan components  
- 32-bit libraries  

You may see errors about these components — this is expected and can be ignored.

When running the installer:

- Select **"No"** when asked:  
  *"Would you like to configure an X server?"*

## Run the NVIDIA driver installer

Execute the installer with root privileges:

```bash
sudo ./NVIDIA-Linux-x86_64-5xx.1xx.0x.run
```

## Troubleshooting

If you encounter issues:

- Make sure you have exited any graphical session  
- Verify you have the correct driver version for your GPU  
- Check that you have the necessary kernel headers installed
