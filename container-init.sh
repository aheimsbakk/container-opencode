#!/bin/bash
set -e

# Ensure HOME is writable; warn if it is not.
# This is a best-effort check and may fail if the container runs as a non-root user.
if [ ! -w "$HOME" ]; then
    echo "WARNING: $HOME is not writable. Some initialization steps may fail."
fi

# Copy default skel files into the user's home without overwriting newer files.
rsync -ur /etc/skel/. "$HOME"/

# If the first argument starts with a dash (e.g. -c), treat it as an option for bash
# and prepend /bin/bash so options are passed to the shell.
if [ "${1#-}" != "$1" ]; then
    set -- /bin/bash "$@"
fi

# Create a minimal .gitconfig with a safe.directory entry if it doesn't already exist.
if [ ! -f "$HOME/.gitconfig" ]; then
    cat <<EOF > "$HOME/.gitconfig"
[safe]
    directory = /work
EOF
fi

# Execute the supplied command (defaults to a shell when no explicit command is given).
exec "$@"
