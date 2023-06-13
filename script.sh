#!/bin/bash
#TODO: Make variable names more logical and clear
#TODO: Fragment the script more... putting functions of similar categories inside another script and source it here
#TODO: get rid of using the IFS variable and the expand aliases
EXTRACTDIR="/acpipatcher/raw_tables"
DUPLICATEDIR="/acpipatcher/duplicate_tables"
BIOSFOLDER="/acpipatcher/installer_dump"
CONTENTFOLDER="/acpipatcher/bios_contents"
IFS=$'\n'
shopt -s expand_aliases

extract_binary=./uefiextract # TODO: decide if this variable is really needed

#TODO: Clean up the alias and source, maybe source aliases too ??
alias fstr='grep -oaPrl'

cleanup() { #function to clean up folders of the old tables - we don't want to mix up tables from different sessions, even from different bioses
	rm -rf $EXTRACTDIR/*
	rm -rf $DUPLICATEDIR/*
}

get_binary() { #simple function to grab latest release of UEFIExtract, unzip it and cleanup after itself
	#TODO: Make more modular... e.g. user could choose version or use a fork of uefitool even ???
	wget -q $(curl -s https://api.github.com/repos/LongSoft/UEFITool/releases/latest | grep browser_download_url | grep linux | grep Extract | head -n 1 | cut -d '"' -f 4)
	echo "Unzipping and cleaning..."
	unzip -q *_linux.zip
	rm *_linux.zip
	#TODO: this function feels error prone... could be borked with change of pipeline over at UEFITool
}

get_tables() {
	declare -i iter=1
	for i in $(fstr $1 $CONTENTFOLDER); do
		if hexdump -C -n 4 $i | grep -q $1; then
			cp $i $2/$1-$iter${i:(-4)}
			iter+=1
		fi
	done
}

extract_bios() { #extracting .exe of bios into bios dump folder
	7z e $1 -o$2 > 7zip_log
	$extract_binary $2/*.fd dump > uefiextract.log
}

decompile(){
	duplicate=$(echo $(cd $EXTRACTDIR && iasl -ve -e $1-*.bin -d $2-1.bin | grep "Firmware Error (ACPI): Failure creating named object" | grep "AE_ALREADY_EXISTS" | cut -f8 -d ' ' | awk '{print substr($0, 2, length($0)-3)}'))
	if [ duplicate != NULL ]; then
		remove_duplicates $duplicate
	else
		echo "Success!"
	fi
}

remove_duplicates() {
	echo "Removing duplicates for method $1"
	#TODO: xxd would be better than hexdump here, would have to rewrite the script to use xxd instead
	#hexdup=$(echo -n $1 | hexdump -ve '"%X"')
	#escseq=$(echo -n 08040AFF0AFF0000)
	
	for i in $(fstr $1 $EXTRACTDIR); do
		filename=$(basename $i)
		cp $i $DUPLICATEDIR
		iasl -d $DUPLICATEDIR/$filename
		#dup=$(hexdump -ve '"%X"' $DUPLICATEDIR/$filename | grep -o $hexdup.*$escseq) This does not apply to all tables
		#echo "Duplicate method hex is $dup"
		#TODO: find a way to detect the end of the duplicate method and replace it with zeros
		#TODO: automatically replace the duplicate part with zeros, of course we have to determine one file that we keep as is (maybe??)
	done
	echo "This script only detects and decompiles duplicates for now. Stay tuned for automatic removal and decompilation."
}

if [ -d "$EXTRACTDIR" ]; then
	#TODO: rewrite to only cleanup if the folder contains something... this way the cleanup occurs everytime we start the script
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
fi

if [ -e "$CONTENTFOLDER" ]; then
	rm -rf $CONTENTFOLDER
fi

ln -s $(find . -name '*.dump') $CONTENTFOLDER #TODO: Works fine... but I am not happy with it... maybe changing the folder structure a bit would help
	
echo "Extracting fresh tables..."
get_tables "SSDT" $EXTRACTDIR
get_tables "DSDT" $EXTRACTDIR

echo "Starting decompilation..."
#TODO: We should put the decompilation in while loop until it responds with 0... That should mean we got rid of all the duplicates... Think of some way to make it more safe than to put in a loop, depending on the tables it could loop itself into oblivion (probably) This comes after we implemented the automatic removal of duplicates
decompile "SSDT" "DSDT"

exit 0

