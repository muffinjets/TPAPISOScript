#!/bin/bash
echo "Welcome!  PLEASE READ THE FOLLOWING:"
echo "1. This script is for Linux systems!  This was written on an Arch setup, but most of the tooling here is distro-agnostic."
echo "2. If you've already set up the REL Loader, be aware that Dolphin will share save files between vanilla/REL and this method, so you will need to be careful to NOT load the REL Loader save file when launching the modified ISO."
echo "3. This script assumes that you are using the Dolphin emulator flatpak (org.DolphinEmu.dolphin-emu) and will install/update it automatically as the script runs."
echo ". This script needs sudo permissions, because it will download relpatchers that aren't exectuable by default.  Don't trust anyone with your sudo password blindly!  I encourage you to check the script and see exactly what I do with it."
sudo -v || exit 1

# keep sudo alive because file downloads are slow
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# comment this out if you don't like it
# it's my birthday, mom says I decide which packaging format is best
sudo flatpak install org.DolphinEmu.dolphin-emu -y
sudo flatpak update org.DolphinEmu.dolphin-emu -y

mkdir TPAPISOScript
cd TPAPISOScript

# cleans up previous relpatch directories and zips for repeated runs (mostly debug)
rm -r relpatch/
rm relpatch.zip


# today I learned that not every distro ships with a cli method of extracting zips
extract_zip() {
    zip="$1"

    if command -v unzip >/dev/null 2>&1; then
        unzip "$zip"
    elif tar -tf "$zip" >/dev/null 2>&1; then
        tar -xf "$zip"
    elif command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "$zip"
    fi
}


# cd ~/.local/share/Archipelago/
pwd
# downloads the iso patch files from the tprandomizer site
curl -L0 https://tprandomizer.com/downloads/relpatch.zip --output relpatch.zip
extract_zip relpatch.zip
cd ./relpatch/
pwd
# this admittedly appears as the sketchiest part on an initial glance and mostly happens because at the time of writing this I didn't realize that the website generates the patch file on the fly.  However, the aptest seed hasn't been updated since January of 2025, though, so my backup probably won't cause issues.
curl -L0 https://github.com/muffinjets/TPAPISOScript/raw/refs/heads/main/Tpr-E-APTest_APT-aptest.gci --output Tpr-E-APTest_APT-aptest.gci
mv Tpr-E-APTest_APT-aptest.gci rels/seed/

# wayland devs please just standardize protocols, why can't I just use xdg-desktop :notlikethis:
if command -v zenity >/dev/null; then
    file=$(zenity --file-selection --title="Select Twilight Princess ISO file.")
elif command -v kdialog >/dev/null; then
    file=$(kdialog --getopenfilename --title="Select Twilight Princess ISO file.")
else read -e -rp "GUI file chooser not found.  Enter absolute filepath to Twilight Princess ISO file: " file
fi

if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "Error: File not found, chosen file wasn't an .iso, or user cancelled operation. Exiting..."
    exit 1
fi

# this whole bit could be improved, but it's what I know how to do.
pwd
echo $file
cp "$file" isos/tp.iso
# here's literally the one place where I need sudo!
sudo chmod +x bin/*
cd bin
./relpatcher
cd ../output
rename tp.iso TwilightPrincessAP.iso *
cd ../..

# I gotta figure out how to pull the latest version so this can be truly one-click
echo "Downloading apworld/RandomizerAP.gci 0.3.0."
curl -L0 https://github.com/WritingHusky/Twilight_Princess_apworld/releases/download/v0.3.0/Twilight_Princess_apworld-v0.3.0.zip --output Twilight_Princess_apworld-v0.3.0.zip
extract_zip Twilight_Princess_apworld-v0.3.0.zip
cp RandomizerAP.us.gci /home/muffinjets/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC/USA/Card\ A/
flatpak run org.DolphinEmu.dolphin-emu relpatch/output/TwilightPrincessAP.iso
echo "Done!  Dolphin should launch automatically, but you'll need to open Archipelago yourself."
