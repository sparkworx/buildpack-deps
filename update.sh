#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

debian="$(curl -fsSL 'https://raw.githubusercontent.com/docker-library/official-images/master/library/debian')"
ubuntu="$(curl -fsSL 'https://raw.githubusercontent.com/docker-library/official-images/master/library/ubuntu')"
centos="$(curl -fsSL 'https://raw.githubusercontent.com/docker-library/official-images/master/library/centos' )"
oraclelinux="oraclelinux7 oraclelinux7-slim" # hard-coded hack, similar to "centos{digit}"

travisEnv=
for version in "${versions[@]}"; do
	if echo "$debian" | grep -qE "\b$version\b"; then
		dist='debian'
	elif echo "$ubuntu" | grep -qE "\b$version\b"; then
		dist='ubuntu'
	elif echo "$centos" | grep -qE "\b$version\b"; then
		dist='centos'
	elif echo "$oraclelinux" | grep -qE "\b$version\b"; then
		dist='oraclelinux'
	else
		echo >&2 "error: cannot determine repo for '$version'"
		exit 1
	fi
	for variant in curl scm ''; do
		case $dist in
			centos|oraclelinux)
				# rpm-yum-ish distros
				src="Dockerfile${variant:+-$variant}-yum.template"
				trg="$version${variant:+/$variant}/Dockerfile"
				;;
			*)
				# deb-apt-ish distros
				src="Dockerfile${variant:+-$variant}.template"
				trg="$version${variant:+/$variant}/Dockerfile"
				;;
		esac
		mkdir -p "$(dirname "$trg")"
		if [[ $variant == curl && $dist == oraclelinux ]] ; then
    # Oracle Linux uses {digit} versions only,
    # so customize tag on "curl" variant.
		( set -x && sed '
			s!DIST!'"$dist"'!g;
			s!SUITE!'"${version##${dist}}"'!g;
		' "$src" > "$trg" )
		else
		( set -x && sed '
			s!DIST!'"$dist"'!g;
			s!SUITE!'"$version"'!g;
		' "$src" > "$trg" )
		fi
	done
	travisEnv+='\n  - VERSION='"$version"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
