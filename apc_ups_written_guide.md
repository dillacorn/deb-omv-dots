APC UPS configuration
https://youtu.be/MyXrlRUBqyg

install apcupsd
```sh
apt install apcupsd
```

## Modify autostart enablement
```sh
nano /etc/default/apcupsd
```
- change "ISCONFIGURED=yes"

## Temporarily stop service
```sh
/etc/ini.d/apcupsd stop
```

## Comment out line in apcupsd.conf
```sh
nano /etc/apcupsd/apcupsd.conf
```
- find line "DEVICE /dev/ttyS0" and comment out (add # at beginning of line)

## Test connection (You should get SUCCESS with options)
```sh
apctest
```
- quit by typing "q" then "enter"

## Start service
```sh
/etc/init.d/apcupsd start
```

:) You're good to go! - next time you get a poweroutage your server is safe!
Additonally I suggest turning on in BIOS - "AC Power On" - so when your server receives power again it will turn on by itself!

---

Optionally change within "apcupsd.conf"
```sh
nano /etc/apcupsd/apcupsd.conf
```
### My changed settings in config
```
BATTERYLEVEL 30
MINUTES 10
```

Restart service when making changes to the config.
```sh
/etc/ini.d/apcupsd stop
```
```sh
/etc/ini.d/apcupsd start
```