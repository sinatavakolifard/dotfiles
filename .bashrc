#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# To keep history when we exit terminal with $MOD+C
# PROMPT_COMMAND is the command that will be executed after every command
export PROMPT_COMMAND="history -a" 

# To stop logging of consecutive identical commands
export HISTCONTROL=ignoredups

# Change saved history size
export HISTSIZE=10000
export HISTFILESIZE=20000

# Pass commands
# alias passc='pass -c $(python3 ~/.config/hypr/scripts/pass_path_generator.py "$(pass)" | fzf --reverse)'
alias passc="PASSWORD=\$(python3 ~/.config/hypr/scripts/pass_path_generator.py \"\$(pass)\" | fzf --reverse) && echo \$PASSWORD | awk -F'/' '{print \$NF}' | wl-copy && pass -c \$PASSWORD"
alias passd='pass delete $(python3 ~/.config/hypr/scripts/pass_path_generator.py "$(pass)" | fzf --reverse)'
alias code='code --ozone-platform=wayland'