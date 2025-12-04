# Hyprland dotfiles on my Arch Linux

This repository consists of my dotfiles for Hyprland in Arch Linux. It looks like this:

![Diagram](images/workspace_screenshot.png)

Next, there is a simple instruction to set up a complete Arch Linux with Hyprland. Keep in mind that some packages might be specific to my system. So you need to find and install ones which are compatible to your system. 

## Install these packages for a basic Arch linux
`sudo pacman -S base base-devel linux linux-firmware sof-firmware intel-ucode intel-media-driver mesa sudo git nano man-db man-pages texinfo tlp`


## Install these packages for these configs
`sudo pacman -S hyprland hyprpaper hypridle hyprpaper hyprpolkitagent xdg-desktop-portal-hyprland waybar wofi swaync alacritty ttf-firacode-nerd pavucontrol brightnessctl blueberry networkmanager upower grim slurp wl-clipboard libnotify fzf udiskie`


## Give execution permissions to scripts
`chmod +x .config/waybar/scripts/*`


## Install these packages for a complete Arch linux with Hyprland
`sudo pacman -S qt5-wayland qt6-wayland firefox mpv zathura zathura-pdf-mupdf feh superfile ttf-dejavu ttf-liberation adw-gtk-theme timeshift`


## Enable these services afterward
```
sudo systemctl enable tlp.service
sudo systemctl start tlp.service
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service
```


## Add wifi connection which has username and password

1. Search for available wifis:
```
nmcli device wifi list
```

2. If the security of the wifi you want is WPA2 802.1X:
```
nmcli connection add \
  type wifi ifname wlp0s20f3 con-name "<SSID>" ssid "<SSID>" \
  wifi.hidden yes \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.identity "<YOUR_USERNAME>" \
  802-1x.password "<YOUR_PASSWORD>" \
  802-1x.phase2-auth mschapv2 \
  connection.autoconnect yes
nmcli connection up "<YOUR_USERNAME>" --ask
```


## Timeshift - reate snapshots (in ext4 hard disk format)

After setting up everything, create a snapshot of your system with Timeshift so that if in the future you face any breaks in your system, you can easily revert to previous versions.

### Listing snapshots:

`sudo timeshift --list`

### Creating a snapshot:

`sudo timeshift --create --comments "comment"`

### Restoring a snapshot:

`sudo timeshift --restore --snapshot "snapshot"`

### Deleting a snapshot:

`sudo timeshift --delete --snapshot "snapshot"`

To create snapshot of Btrfs filesystems or getting more info, visit this link: https://wiki.archlinux.org/title/Timeshift


## Mount and unmount USBs and external hard disks

Hyprland by default does not support automatic mounting and unmounting external devices like USBs. To make mounting automatic, use this in hyprland.conf:

`exec-once = udiskie`

To unmount a disk and detach it so that you can safely remove it:

```
lsblk
udiskie-umount --detach /run/media/<username><external_usb_name>
```

To manually mount a device if it fails:
```bash
lsblk
udiskie-mount /dev/sda1
```

More info: https://man.archlinux.org/man/extra/udiskie/udiskie.8.en