#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# if uwsm check may-start && uwsm select; then
# 	exec systemd-cat -t uwsm_start uwsm start default
# fi

# To bypass compositor selection menu and launch Hyprland directly
# if uwsm check may-start; then
#   exec uwsm start hyprland.desktop
# fi

# Start with this. Starting with uwsm crashes in some use cases.
if [ "$(tty)" = "/dev/tty1" ];then
  # Hybrid-GPU laptop only: /dev/dri/{igpu,dgpu} come from a udev rule
  # (/etc/udev/rules.d/61-gpu-names.rules). Machines without it skip this.
  if [[ -e /dev/dri/dgpu ]]; then
    # Only hand the dGPU to Hyprland when an external monitor is on its ports;
    # otherwise Hyprland (and Xwayland via DRM lease) keep it from suspending.
    # Plugging a monitor into the dGPU ports later requires re-login.
    export AQ_DRM_DEVICES=/dev/dri/igpu
    for c in /sys/class/drm/"$(basename "$(readlink -f /dev/dri/dgpu)")"-*; do
      [[ $c == *eDP* ]] && continue
      if [[ $(cat "$c/status" 2>/dev/null) == connected ]]; then
        AQ_DRM_DEVICES=/dev/dri/igpu:/dev/dri/dgpu
        break
      fi
    done
    # glvnd loads every EGL vendor, and NVIDIA's opens /dev/nvidia0 during device
    # enumeration even when unused. Force Mesa when the dGPU isn't needed.
    # EGL apps under prime-run then also need:
    #   __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
    if [[ $AQ_DRM_DEVICES == /dev/dri/igpu ]]; then
      export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
    fi
    # Keep apps on the iGPU by default; use `prime-run <app>` to run something on the dGPU
    export LIBVA_DRIVER_NAME=iHD
    export MOZ_DRM_DEVICE=/dev/dri/by-path/pci-0000:00:02.0-render
    export MESA_VK_DEVICE_SELECT=8086:7d67
  fi
  # exec Hyprland
  exec start-hyprland
fi
