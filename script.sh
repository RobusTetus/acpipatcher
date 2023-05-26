#!/usr/bin/env bash
IFS=$'\n'
source .env

cleanup() {
	rm -rf $extract_dir/*
	rm -rf $duplicate_dir/*
}

get_binary() {
	echo "Starting download of UEFIExtract..."
	wget -q $(curl -s https://api.github.com/repos/LongSoft/UEFITool/releases/latest | grep browser_download_url | grep linux | grep Extract | head -n 1 | cut -d '"' -f 4)
	echo "Unzipping and cleaning..."
	unzip -q *_linux.zip
	rm *_linux.zip
}

get_tables() {
	declare -i iter
	iter=1
	hex=$(echo $1 | hexdump -v -e '/1 "%02X "' | awk '{print "(\\x" $1 "\\x" $2 "\\x" $3 "\\x" $4 ")"}')
	
	for i in $(grep -oaPrl $hex $bios_folder); do
		if hexdump -C -n 4 $i | grep -q $1; then
			cp ${i} $2/$1-$iter${i:(-4)}
			iter+=1
		fi
	done
	
	return 0
}

extract_bios() {
	7z e $1 -o./$2 > 7zip_log
	$extract_binary ${2:-"./"}/*.fd > uefitool_log
	return 0
}

decompile(){
	duplicate=$(echo $(cd $extract_dir && iasl -ve -e "$SSDT-*.bin" -d "$DSDT-1.bin" | grep "Firmware Error (ACPI): Failure creating named object" | grep "AE_ALREADY_EXISTS" | cut -f8 -d ' ' | awk '{print substr($0, 2, length($0)-3)}'))
	if [ duplicate != NULL ]; then
		remove_duplicates $duplicate
	else
		echo "Success!"
	fi
}

remove_duplicates() {
	for i in $(grep -l $1 * | uniq); do
		cp $i $duplicate_dir
		$(cd $duplicate_dir && iasl -d /$i)
		echo "Separated duplicates and decompiled them..."
		hexdup=$(echo $1 | hexdump -v -e '/1 "%02X "' | sed 's/ //g')
		escseq=$( echo "08 04 0A FF 0A FF 00 00" | sed 's/ //g' )
		dup=$(hexdump -ve '1/1 "%.2x"' $duplicate_dir/$i | grep -i --exclude-dir=* "${hexdup}.*${escseq}")
		echo $dup
	done
}

if [ ! -e "$bios_folder" ]; then
	if [ ! -e "$extract_binary" ]; then get_binary; fi
	extract_bios $1 $bios_folder
fi

if [ -d "$extract_dir" ]; then
	echo "Cleaning..."
	cleanup
fi

echo "Extracting fresh tables..."
get_tables $SSDT $extract_dir
get_tables $DSDT $extract_dir

echo "Starting decompilation..."
decompile $SSDT $DSDT

echo "Exiting script. Be sure to backup the tables before you run this script again!"
return 0
