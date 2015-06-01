#!/bin/sh
# usage: test-stages.sh [no args]
# Runs a Sabotage installation from scratch through stage 0 and stage 1, automatically.
# Intended for basic automated testing (for example, does it actually build?)

# The configuration is generated automatically from the host machine specs.
# If specified, the environment variables CC and HOSTCC will be set in the configuration.

set -e

cd "$(dirname $0)/.."

if [ -e config ]; then
	echo "error: cowardly refusing to overwrite your existing config in $PWD." 1>&2
	exit 1
fi

# Build sabotage in a new, non-existant directory.
BUILDDIR="$(mktemp -d)/sabotage"
echo "Building Sabotage in '$BUILDDIR'..."

# We now (effectively) follow the build instructions from COOKBOOK.md below,
# as if we were a new user.
cp KEEP/config.stage0 config

sed -i -e "s@^\(export SABOTAGE_BUILDDIR=\).*\$@\1$BUILDDIR@" \
       -e "s@^\(export A=\).*\$@\1$(uname -m)@" \
       -e "s@^\(export MAKE_THREADS=\).*\$@\1$(grep -c 'processor\s*:' /proc/cpuinfo)@" \
       -e "s@^\(export CC=\)\(.*\)\$@\1${CC:-\2}@" \
       -e "s@^\(export HOSTCC=\)\(.*\)\$@\1${HOSTCC:-\2}@" \
       config

./build-stage0
SUPER=1 ./enter-chroot
./butch install stage1
