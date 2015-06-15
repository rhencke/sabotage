#!/bin/sh

set -e

# Binaries we depend on from busybox can be clobbered during unlinking
# (for example, relink busybox, unlink gawk unlinks busybox awk).  This
# attempts to mitigate the effects of this.
export PATH=/opt/busybox/bin:"$PATH"

. "$(dirname $0)/../config"

CRAP="$(mktemp -d)"
trap "rm -fr \"$CRAP\"" EXIT
cd "$CRAP"

# TODO: logging that doesn't suck
# TODO: resume/retry/partial?

mkdir essential
mkdir failed
mkdir logs

# As stage1 is the starting point, all stage1 dependencies are considered essential.
# stage1, oddly, does not include stage0
for pkg in $(awk -f "$S"/utils/print-pkg-build-order.awk stage0 stage1); do
	touch essential/"$pkg"
done

link_only_essential() {
	# Start by unlinking all non-essential packages, then re-link only essential packages.
	# This should put the environment in a state that should be equivalent to just after
	# a clean stage1 install.  We use this to detect missing package dependencies.
	INSTALLED=$(butch list)
	for action in unlink relink; do
		for installed in $INSTALLED; do
			if [ -e essential/"$installed" ]; then
				# skip unlinking if package is essential
				[ "$action" == "unlink" ] && continue
			else
				# skip relinking if package is non-essential
				[ "$action" == "relink" ] && continue
			fi
			# Some packages have nothing to unlink/relink
			# TODO: something better than ignoring errors
			butch "$action" "$installed" || true
		done
	done
}

echo Building all packages... this will take a while.

for pkgToTest in $(awk -f "$S"/utils/print-pkg-build-order.awk $(ls "$S"/pkg)); do
	exec 3>"$CRAP"/logs/"$pkgToTest"
	if [ -e essential/"$pkgToTest" ]; then
		echo PASS - $pkgToTest
		continue
	fi

	link_only_essential 1>&3 2>&3

	for pkg in $(awk -f "$S"/utils/print-pkg-build-order.awk "$pkgToTest"); do
		if [ -e failed/"$pkg" ]; then
			echo SKIP - $pkgToTest \(failed to build prerequisite: $pkg\) >&2
			break
		fi
		if [ "$pkgToTest" == "$pkg" ]; then
			if butch rebuild "$pkg" 1>&3 2>&3; then
				echo PASS - $pkg
			else
				echo FAIL - $pkg \(check package build log\) >&2
				touch failed/"$pkg"
			fi
		else
			# TODO - don't ignore errors.
			butch relink "$pkg" 1>&3 2>&3 || true
		fi
	done
done
