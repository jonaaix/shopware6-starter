# --- Custom Bash Prompt and Aliases ---

force_color_prompt=yes
if [ "$force_color_prompt" = yes ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='\[\033[01;32m\]\u@\h:\[\033[01;34m\]\w\$ \[\033[00m\]'
else
  PS1='\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

alias ll='ls -lsah'
alias bc="bin/console"
alias pa="bin/console"
