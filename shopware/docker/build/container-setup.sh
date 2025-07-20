#!/bin/sh

set -e

apk update && \
apk add --no-cache bash bash-completion less nano curl wget shadow rsync

# Set default shell to bash for all users that currently use /bin/ash
for user in $(cut -d: -f1 /etc/passwd); do
  current_shell=$(getent passwd "$user" | cut -d: -f7)
  if [ "$current_shell" = "/bin/ash" ]; then
    chsh -s /bin/bash "$user" || echo "Could not change shell for $user"
  fi
done

# Global bashrc file
GLOBAL_BASHRC="/etc/bash.bashrc"
touch "$GLOBAL_BASHRC"

# Source bash completion if not already in
if ! grep -q '/etc/profile.d/bash_completion.sh' "$GLOBAL_BASHRC"; then
  echo "if [ -f /etc/profile.d/bash_completion.sh ]; then . /etc/profile.d/bash_completion.sh; fi" >> "$GLOBAL_BASHRC"
fi

# Append bash config
cat /tmp/bash-config.sh >> "$GLOBAL_BASHRC"

# Ensure all users source it
for user in $(cut -d: -f1 /etc/passwd); do
  home_dir=$(getent passwd "$user" | cut -d: -f6)
  if [ -d "$home_dir" ]; then
    user_rc="$home_dir/.bashrc"
    touch "$user_rc"
    if ! grep -q "$GLOBAL_BASHRC" "$user_rc"; then
      echo "[ -f $GLOBAL_BASHRC ] && . $GLOBAL_BASHRC" >> "$user_rc"
    fi
    chown "$user:$user" "$user_rc" || true
  fi
done

# Install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php
mkdir -p /tmp/composer
chown -R shopware:shopware /tmp/composer
