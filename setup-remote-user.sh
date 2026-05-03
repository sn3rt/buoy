#!/usr/bin/env bash
set -euo pipefail

# Sets up a personal user account on a shared Ubuntu machine.
# The personal user joins the shared user's group and can read the shared
# home, but their own home dir (and credentials) are private.
#
# Usage:
#   sudo ./setup-remote-user.sh <shared-user> <personal-user> \
#       [--ssh-key "pubkey"] [project-dir ...]
#
# Example:
#   sudo ./setup-remote-user.sh team peter \
#       --ssh-key "ssh-ed25519 AAAA..." /home/team/projects

usage() {
  printf 'usage: sudo %s <shared-user> <personal-user> [--ssh-key "pubkey"] [project-dir ...]\n' \
    "$(basename "$0")" >&2
}

log() {
  printf '%s\n' "$*"
}

# ---------------------------------------------------------------------------
# Argument parsing

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

shared_user="$1"
personal_user="$2"
shift 2

ssh_key=""
project_dirs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh-key)
      if [[ $# -lt 2 ]]; then
        printf 'setup-remote-user: --ssh-key requires a value\n' >&2
        exit 1
      fi
      ssh_key="$2"
      shift 2
      ;;
    -*)
      printf 'setup-remote-user: unknown flag: %s\n' "$1" >&2
      usage
      exit 1
      ;;
    *)
      project_dirs+=("$1")
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation

if [[ $EUID -ne 0 ]]; then
  printf 'setup-remote-user: must be run as root (use sudo)\n' >&2
  exit 1
fi

if ! id "$shared_user" >/dev/null 2>&1; then
  printf 'setup-remote-user: shared user does not exist: %s\n' "$shared_user" >&2
  exit 1
fi

if ! printf '%s' "$personal_user" | grep -qE '^[a-z_][a-z0-9_-]*$'; then
  printf 'setup-remote-user: invalid username: %s\n' "$personal_user" >&2
  exit 1
fi

shared_home="$(eval printf '%s' "~$shared_user")"
if [[ ! -d "$shared_home" ]]; then
  printf 'setup-remote-user: shared home not found: %s\n' "$shared_home" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Group setup

shared_group="$(id -gn "$shared_user")"
log "[group] shared group: $shared_group"

# ---------------------------------------------------------------------------
# Shared home permissions

log "[shared] setting $shared_home to 750 (group-readable)"
chown "$shared_user:$shared_group" "$shared_home"
chmod 750 "$shared_home"

# ---------------------------------------------------------------------------
# Personal user

if id "$personal_user" >/dev/null 2>&1; then
  log "[user] $personal_user already exists, skipping creation"
else
  log "[user] creating $personal_user"
  useradd -m -s /bin/bash "$personal_user"
fi

personal_home="$(eval printf '%s' "~$personal_user")"
log "[user] setting $personal_home to 700 (private)"
chmod 700 "$personal_home"

# ---------------------------------------------------------------------------
# Group membership

log "[group] adding $personal_user to $shared_group"
usermod -aG "$shared_group" "$personal_user"

# ---------------------------------------------------------------------------
# SSH key

if [[ -n "$ssh_key" ]]; then
  ssh_dir="$personal_home/.ssh"
  auth_keys="$ssh_dir/authorized_keys"

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ -f "$auth_keys" ]] && grep -qF "$ssh_key" "$auth_keys"; then
    log "[ssh] key already in authorized_keys, skipping"
  else
    printf '%s\n' "$ssh_key" >> "$auth_keys"
    log "[ssh] key added to $auth_keys"
  fi

  chmod 600 "$auth_keys"
  chown -R "$personal_user:$personal_user" "$ssh_dir"
fi

# ---------------------------------------------------------------------------
# Project dirs

for dir in "${project_dirs[@]}"; do
  if [[ ! -d "$dir" ]]; then
    printf 'setup-remote-user: project dir not found: %s\n' "$dir" >&2
    exit 1
  fi
  log "[project] setting up $dir"
  chown -R "$shared_user:$shared_group" "$dir"
  chmod -R g+rw "$dir"
  find "$dir" -type d -exec chmod g+s {} +
done

# ---------------------------------------------------------------------------
# Summary

hostname_str="$(hostname)"

printf '\nDone. Next steps for %s:\n' "$personal_user"
if [[ -z "$ssh_key" ]]; then
  printf '  1. Set a password:    sudo passwd %s\n' "$personal_user"
  printf '  2. SSH in:            ssh %s@%s\n' "$personal_user" "$hostname_str"
else
  printf '  1. SSH in:            ssh %s@%s\n' "$personal_user" "$hostname_str"
fi
printf '  %s. Clone dotfiles:    git clone <repo> ~/dots\n' "$([[ -z "$ssh_key" ]] && printf 3 || printf 2)"
printf '  %s. Link configs:      cd ~/dots && ./install.sh\n' "$([[ -z "$ssh_key" ]] && printf 4 || printf 3)"
printf '  %s. Install tools:     ./install-tools.sh\n' "$([[ -z "$ssh_key" ]] && printf 5 || printf 4)"
