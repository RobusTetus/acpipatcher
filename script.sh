#!/usr/bin/env bash
IFS=$'\n'
extract_dir="tables"
extract_binary="./uefiextract"
DSDT="DSDT"
SSDT="SSDT"
bios_folder="dump"
workdir=$(pwd)

source .env

get_UEFIExtract() {
	echo "Starting download of UEFIExtract..."
	wget -q $(curl -s https://api.github.com/repos/LongSoft/UEFITool/releases/latest | grep browser_download_url | grep linux | grep Extract | head -n 1 | cut -d '"' -f 4)
	echo "Unzipping and cleaning..."
	unzip -q *_linux.zip
	rm *_linux.zip
	return 0
}

get_tables() {
	declare -i iter
	iter=1
	hex=$(echo $1 | hexdump -v -e '/1 "%02X "' | awk '{print "(\\x" $1 "\\x" $2 "\\x" $3 "\\x" $4 ")"}')
	for i in $(grep -oaPrl ${hex:-"(\x53\x53\x44\x54)"}); do
		if hexdump -C -n 4 $i | grep -q ${1:-"SSDT"}; then
			cp ${i} ${2:-"DSDT"}/${1:-"SSDT"}-$iter${i:(-4)}
			iter+=1
		fi
	done
	return 0
}

extract_bios() {
	7z e ${1:-"*.exe"} -o./$2 > 7zip_log
	./$extract_binary ${2:-"./"}/*.fd > uefitool_log
	return 0
}

decompile(){
	cd $extract_dir
	duplicate=$(echo $(iasl -ve -e SSDT-*.bin -d DSDT-1.bin | grep "Firmware Error (ACPI): Failure creating named object" | grep "AE_ALREADY_EXISTS" | cut -f8 -d ' ' | awk '{print substr($0, 2, length($0)-3)}'))
	if [ duplicate != "" ]; then
		remove_duplicates $duplicate
	else
		echo "Success!"
		return 0
	fi
}

remove_duplicates() {
	dups="dups"
	mkdir -p $dups
	for i in $(grep -l $1 * | uniq); do
		cp $i $dups
		iasl -d $dups/$i
		echo "Separated duplicates and decompiled them..."
		hexdup=$(echo $1 | hexdump -v -e '/1 "%02X "' | sed 's/ //g')
		escseq=$( echo "08 04 0A FF 0A FF 00 00" | sed 's/ //g' )
		dup=$(hexdump -ve '1/1 "%.2x"' $dups/$i | grep -i "${hexdup}.*${escseq}")
	done
	return 0
}

if [ ! -e "$bios_folder" ]; then
	if [ ! -e "$extract_binary" ]; then get_UEFIExtract; fi
	extract_bios ${1:-"*.exe"} $bios_folder
fi

if [ -d "$extract_dir" ]; then
	echo "Removing old tables..."
	rm -rf $extract_dir/*
else
	mkdir -p $extract_dir
fi

echo "Extracting fresh tables..."
get_tables $SSDT $extract_dir
get_tables $DSDT $extract_dir

echo "Starting decompilation..."
decompile $SSDT $DSDT

echo "Exiting script. Be sure to backup the tables before you run this script again!"

