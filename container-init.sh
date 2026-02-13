#!/bin/bash
set -e

if [ ! -w "$HOME" ]; then
    echo "ADVARSEL: Mangler skriverettigheter til $HOME."
    # Dette vil feile hvis brukeren ikke er root, men verdt et forsøk eller en warning
fi

rsync -ur /etc/skel/. $HOME/

# Hvis første argument starter med en bindestrek (f.eks. -c), anta at det er til bash
if [ "${1#-}" != "$1" ]; then
	set -- /bin/bash "$@"
fi

cat <<EOF > $HOME/.gitconfig
[safe]
	directory = /work
EOF

# Dette kjører kommandoen som ble gitt til containeren (default: /bin/bash)
exec "$@"
