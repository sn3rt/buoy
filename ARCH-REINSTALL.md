# Files To Keep Before Reinstalling

Copy these to an encrypted external disk while preserving permissions:

- `~/.ssh/` - SSH keys, aliases, and known hosts.
- `~/.config/secrets/` - private dotfile values.
- `/etc/hosts` - local host aliases.
- `/var/lib/zerotier-one/` - ZeroTier identity and networks.
- `/etc/netbird/` and `/var/lib/netbird/` - NetBird identity and configuration.
- `/etc/iwd/` and `/var/lib/iwd/` - IWD configuration and saved Wi-Fi networks.
- `/etc/NetworkManager/system-connections/` - additional NetworkManager profiles.
- `~/.gitconfig` - Git identity and settings.
- `~/.gnupg/` - only if existing GPG keys are needed.
- `/etc/ssh/ssh_host_*` - only if this machine must retain its SSH server identity.
