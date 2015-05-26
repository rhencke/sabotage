#!/bin/sh
# usage: test-stages.sh [no args]
# Runs a Sabotage installation from scratch through stage 0 and stage 1, automatically.
# Intended for basic automated testing (for example, does it actually build?)

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

sed -i -r -e '/^export (SABOTAGE_BUILDDIR|A|MAKE_THREADS)=.*$/ d' config
cat << EOF >> config

# added by test-stage0.sh
export SABOTAGE_BUILDDIR=$BUILDDIR
export A=$(uname -m)
export MAKE_THREADS=$(grep -c 'processor\s*:' /proc/cpuinfo)
EOF

./build-stage0
./enter-chroot
./butch install stage1
