#!/usr/bin/bash

die() {
	echo "*** $@"
	exit 1
}

quick=no

if [ $# -eq 1 ]; then
	if [[ "$1" == "--quick" ]]; then
		quick=yes
	else
		die "usage: $0 [--quick]"
	fi
elif [ $# -gt 1 ]; then
	die "usage: $0 [--quick]"
fi

source /etc/makepkg.conf || die "Failed to source /etc/makepkg.conf"
source PKGBUILD || die "No PKGBUILD found..."

pkgfile="${pkgname}-${pkgver}-${pkgrel}-${CARCH}${PKGEXT}"
newrel=$((1+pkgrel))
newfile="${pkgname}-${pkgver}-${newrel}-${CARCH}${PKGEXT}"

if [[ "$quick" == "yes" ]]; then
	case "$pkgfile" in
		*.xz)  compressor=xz    ; unpkgfile="${pkgfile%%.xz}"  ; unnewfile="${newfile%%.xz}"  ;;
		*.bz2) compressor=bzip2 ; unpkgfile="${pkgfile%%.bz2}" ; unnewfile="${newfile%%.bz2}" ;;
		*.gz)  compressor=gzip  ; unpkgfile="${pkgfile%%.gz}"  ; unnewfile="${newfile%%.gz}"  ;;
		*) die "unknown compression used on archive" ;;
	esac

	rm -f .PKGINFO
	echo "Extracting .PKGINFO"
	tar -xf "$pkgfile" .PKGINFO    || die "Error extracting .PKGINFO from archive."

	echo "Relbumping .PKGINFO"
	grep -q "pkgver = ${pkgver}-${pkgrel}" .PKGINFO                      || die "broken package, .PKGINFO contains wrong pkgver"
	sed -i '' -e 's/pkgver =.*/pkgver = '${pkgver}-${newrel}'/' .PKGINFO || die "failed to replace pkgver"
	grep -q "pkgver = ${pkgver}-${newrel}" .PKGINFO                      || die "new package version not showing up..."

	echo "Creating new package..."
	tar -cf "$unnewfile" .PKGINFO                       || die "Failed to initiate package archive"
	tar -rf "$unnewfile" --exclude .PKGINFO "@$pkgfile" || die "Failed to fill package archive"
	rm -f .PKGINFO

	echo "Compressing archive..."
	$compressor "$unnewfile" || die "Failed to compress archive"
	# This usually happens automatically
	rm -f "$unnewfile"
fi

if [ -f "$pkgfile" ]; then
	echo "Removing old package $i"
	rm -vf "$pkgfile" "${pkgfile}.sig"
fi

echo "Relbumping to $pkgname-$pkgver-$newrel"
echo "PKGBUILD backed up as PKGBUILD.oldrel"
sed -i .orig -e 's|^pkgrel.*=.*$|pkgrel='$newrel'|' PKGBUILD

if [[ "$quick" == "yes" ]]; then
	echo "New package available in $newfile"
	echo "Signing..."
	gpg --detach-sign "$newfile" || die "Signing failed - try manually"
	exit 0
fi

if test -d pkg; then
	echo "Repackaging..."
	exec makepkg -R --sign
else
	echo "Building..."
	exec makepkg --sign
fi
