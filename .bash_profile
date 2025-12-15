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
  exec Hyprland
fi

# Put Flutter bin to path 
export PATH="$HOME/Packages/flutter/bin:$PATH"
