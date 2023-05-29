#!/bin/bash
IFS=$'\n'
extract_binary=./uefiextract
source .env

cleanup() { #function to clean up folders of the old tables - we don't want to mix up tables from different sessions, even from different bioses
	rm -rf $EXTRACTDIR/*
	rm -rf $DUPLICATEDIR/*
}

get_binary() { #simple function to grab latest release of UEFIExtract, unzip it and cleanup after itself
	wget -q $(curl -s https://api.github.com/repos/LongSoft/UEFITool/releases/latest | grep browser_download_url | grep linux | grep Extract | head -n 1 | cut -d '"' -f 4)
	echo "Unzipping and cleaning..."
	unzip -q *_linux.zip
	rm *_linux.zip
}

get_tables() { # function to search for our tables in the bios dump folder using hex magic
	declare -i iter=1
	hex=$(echo $1 | hexdump -v -e '/1 "%02X "' | awk '{print "(\\x" $1 "\\x" $2 "\\x" $3 "\\x" $4 ")"}') #converting string to hex format
	for i in $(grep -oaPrl $hex $CONTENTFOLDER); do #searching with grep inside the bios dump folder
		cp $i $2/$1-$iter${i:(-4)} #copying matches into extract directory
		iter+=1 #since we should expect more tables... increment by one
	done
}

extract_bios() { #extracting .exe of bios into bios dump folder
	7z e $1 -o./$2 > 7zip_log
	$extract_binary $2/*.fd dump > uefiextract.log
}

decompile(){
	duplicate=$(echo $(cd $EXTRACTDIR && iasl -ve -e "$1-*.bin" -d "$2-1.bin" | grep "Firmware Error (ACPI): Failure creating named object" | grep "AE_ALREADY_EXISTS" | cut -f8 -d ' ' | awk '{print substr($0, 2, length($0)-3)}'))
	if [ duplicate != NULL ]; then
		echo $duplicate
	else
		echo "Success!"
	fi
}

remove_duplicates() {
	for i in $(grep -l $1 * | uniq); do
		cp $EXTRACTDIR/$i $DUPLICATEDIR
		$(cd $DUPLICATEDIR && iasl -d /$i)
		echo "Separated duplicates and decompiled them..."
		hexdup=$(echo $1 | hexdump -v -e '/1 "%02X "' | sed 's/ //g')
		escseq=$(echo "08 04 0A FF 0A FF 00 00" | sed 's/ //g')
		dup=$(hexdump -ve '1/1 "%.2x"' $DUPLICATEDIR/$i | grep -i "${hexdup}.*${escseq}")
		echo $dup
	done
}

if [ -d "$EXTRACTDIR" ]; then
	echo "Cleaning..."
	cleanup
fi

if [ ! -e "$BIOSFOLDER" ]; then
	mkdir $BIOSFOLDER
	
	if [ ! -e "$extract_binary" ]; then
		echo "Starting download of UEFIExtract..."
		get_binary
	fi
	
	extract_bios $1 $BIOSFOLDER
	
	if [ -e "$CONTENTFOLDER" ]; then
		rm -rf $CONTENTFOLDER
	fi
	#TODO: create symlink with content folder !!! ln -s ... cannot find where is the bios dump folder
fi

echo "Extracting fresh tables..."
get_tables "SSDT" $EXTRACTDIR
get_tables "DSDT" $EXTRACTDIR

echo "Starting decompilation..."
decompile "SSDT" "DSDT"

exit 0

