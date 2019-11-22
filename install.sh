#!/bin/sh

set -e

# Detect if we're installing under termux.
: ${TERMUX:=}
echo "$PREFIX" | grep -q termux && \
	TERMUX=$(dirname "$PREFIX") prefix=${prefix:-/usr}

: ${prefix:=/usr/local}
: ${DESTDIR:=}

verbose() { echo "$@" >&2 && "$@"; }
install_v()
{
	# Install $1 into $2/ with mode $3
	verbose install -d "$2" &&
	verbose install -m "$3" "$1" "$2"
	if [ -n "$TERMUX" ]; then
		# If running under termux, enable gpg_tty assignment.
		sed -i -e "s|^#!/bin/sh$|#!$2/sh|g" \
			"$2/$1"
	fi
}

install_v git-remote-gcrypt "$TERMUX$DESTDIR$prefix/bin" 755

if command -v rst2man >/dev/null
then
	rst2man='rst2man'
elif command -v rst2man.py >/dev/null # it is installed as rst2man.py on macOS
then
	rst2man='rst2man.py'
fi

if [ -n "$rst2man" ]
then
	trap 'rm -f git-remote-gcrypt.1.gz' EXIT
	verbose $rst2man ./README.rst | gzip -9 > git-remote-gcrypt.1.gz
	install_v git-remote-gcrypt.1.gz "$TERMUX$DESTDIR$prefix/share/man/man1" 644
else
	echo "'rst2man' not found, man page not installed" >&2
fi

if [ -n "$TERMUX" ] ; then
	if ! grep -q "^export GPG_TTY" ~/.bashrc ; then
		echo "Setting export for GPG_TTY in ~/.bashrc" >&2
		echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
	fi
fi
