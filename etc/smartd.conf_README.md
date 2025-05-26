# WD Drive SMART Monitoring Fix for OpenMediaVault

## Purpose
1. Fixes false temperature alerts and suppresses firmware-related SMART errors on Western Digital Red drives while maintaining critical health monitoring.
2. OpenMediaVault doesn't allow custom S.M.A.R.T settings for some freaking reason.

## Prerequisites
- OpenMediaVault (with configured SMART settings first)
- WD Red drives (tested with firmware 81.00A81)
- Root access

## Step-by-Step Configuration

### 0. Create a backup:
```bash
sudo cp /etc/smartd.conf /etc/smartd.conf.backup
sudo chattr +i /etc/smartd.conf.backup
```

### 1. Unlock smartd.conf for editing
```bash
sudo chattr -i /etc/smartd.conf
sudo nano /etc/smartd.conf
```

### 2. Replace file contents with: (just an example)
```text
# LOCKED CONFIG - OMV cannot overwrite
DEFAULT -a -o on -S on -T permissive -W 4,40,65 -n never -I 194

# WD Drive 1 (Example: WD80EFZZ-68BTXN0)
/dev/disk/by-id/ata-WDC_WD80EFZZ-68BTXN0_WD-XXXXXXX \
  -d ignore \
  -s (S/../05/./07) \
  -m your@email.com -M exec /usr/share/smartmontools/smartd-runner

# WD Drive 2 (Add additional drives as needed)
/dev/disk/by-id/ata-WDC_WD80EFZZ-68BTXN0_WD-YYYYYYY \
  -d ignore \
  -s (S/../05/./07) \
  -m your@email.com -M exec /usr/share/smartmontools/smartd-runner

# Intel SSD (Example)
/dev/disk/by-id/ata-INTEL_SSDSC2BP240G4_ZZZZZZZZ \
  -s (S/../05/./07) \
  -m your@email.com -M exec /usr/share/smartmontools/smartd-runner
```

### 3. Make the config immutable:
```bash
sudo chattr +i /etc/smartd.conf
sudo systemctl restart smartd
```
End of directions.

If you ever need to edit S.M.A.R.T settings again you will edit them here not in openmediavault UI.
