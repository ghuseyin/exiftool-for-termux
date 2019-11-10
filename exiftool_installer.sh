#!/data/data/com.termux/files/usr/bin/bash

yes_no(){
	local yn
	while true
	do
		read -p "$* [yes/no]: " yn
		case "$yn" in
			[Yy]*) return 0 ;;
			[Nn]*) return 1 ;;
		esac
	done
}
check_requirements(){
	local reqs='tar perl wget gzip make curl'
	for req in $reqs
	do
		pkg list-installed 2> "$PREFIX/tmp/$blackhole" | grep -q "$req"
		if [ "$?" -eq 0 ]
		then echo "$req OK"
		else req_stat+=("$req")
		fi
	done
}

if [ "$UID" -eq 0 ]; then
	echo 'Please run without root.'
	exit 1
fi
declare -a req_stat # for storing not installed requirements
blackhole="null.$RANDOM.null" # for apt not have a stable cli warning redirection
cd ~
pwd
echo 'Checking requirements...'
check_requirements
rm "$PREFIX/tmp/$blackhole"

if [ "${#req_stat[@]}" -gt 0 ]; then
	echo "Need install ${req_stat[@]}"
	yes_no "Do you want to install?"
	if [ "$?" -eq 0 ]; then
		echo "Installing ${req_stat[@]}"
		pkg install "${req_stat[@]}"
		else
			echo 'Aborted!'
			exit 1
	fi
fi
exif_version=$( curl -s 'https://www.sno.phy.queensu.ca/~phil/exiftool/' | grep 'tar.gz' | cut -f 2 -d '"' )
echo "Downloading $exif_version ..."
wget "https://www.sno.phy.queensu.ca/~phil/exiftool/$exif_version"
echo 'Extracting files...'
gzip -dc "$exif_version" | tar -xf -
exif_dir=`echo "$exif_version" | cut -f 1-2 -d '.'`
cd "$exif_dir"
perl Makefile.PL
make
yes_no 'Do you want to testing files (may take time)'
if [ "$?" -eq 0 ]
	then
		echo 'Testing files...'
		make test
fi
echo "Installing $exif_dir ..."
make install
echo 'Done!'
