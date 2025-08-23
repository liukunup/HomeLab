# ReDroid

- https://github.com/remote-android/redroid-doc.git

## Getting Started

From Chocolatey:
```
choco install scrcpy
choco install adb    # if you don't have it yet
```

```
##############################
## Ubuntu 22.04 or 24.04
##############################

## install required kernel modules
apt install linux-modules-extra-`uname -r`
modprobe binder_linux devices="binder,hwbinder,vndbinder"
### optional module (removed since 5.18)
modprobe ashmem_linux

## running redroid
docker run -itd --rm --privileged \
    -v /mnt/workspace/data/redroid:/data \
    -p 5555:5555 \
    --name=redroid \
    redroid/redroid:11.0.0-latest \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=1920 \
    androidboot.redroid_dpi=480

### DISCLAIMER
### Should NOT expose adb port on public network
### otherwise, redroid container (even host OS) may get compromised

## install adb https://developer.android.com/studio#downloads
adb connect localhost:5555
### NOTE: change localhost to IP if running redroid remotely

## view redroid screen
## install scrcpy https://github.com/Genymobile/scrcpy/blob/master/README.md#get-the-app
scrcpy -s localhost:5555
### NOTE: change localhost to IP if running redroid remotely
###     typically running scrcpy on your local PC
```
