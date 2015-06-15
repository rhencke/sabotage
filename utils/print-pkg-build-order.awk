#!/bin/awk -f
# use: print-pkg-build-order.sh <package> [<package>...]
# prints all packages that would be built by building <package>(s), in build order.
BEGIN {
	if (!ENVIRON["S"]) {
		error("$S is not set. be sure to source config: . ./config")
	}
	if (ARGC<2) {
		error("please provide one or more packages to print the build order for.")
	}
	for(a=1; a<ARGC; a++) {
		print_build_order(ARGV[a])
	}
}

function error(msg) {
	print "error: " msg > "/dev/stderr"
	exit 1
}

function print_build_order(pkg,	inDepsSection, dep, pkgFile) {
	pkgFile=ENVIRON["S"] "/pkg/" pkg
	if (SEEN[pkg]) {
		return
	}
	while ((r = getline < pkgFile) == 1) {
		dep=$0
		if (/\[deps(\.host|\.run)?\]/) {
			inDepsSection=1
			continue
		}
		if (/\[/) {
			inDepsSection=0
		}
		if (/^\s*$/ || !inDepsSection) {
			continue
		}
		print_build_order(dep)
	}
	if (r == -1) {
		error("unable to read from " pkgFile) 
	}
	if(SEEN[pkg]) {
		error("circular dependency detected for " pkg ".")
	} 
	print pkg
	SEEN[pkg]=1
	close(pkgFile)
}
