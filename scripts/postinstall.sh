_set_50-synaptics() {
    cat << EOF > ${DESTDIR}/etc/X11/xorg.conf.d/50-synaptics.conf 
# Example xorg.conf.d snippet that assigns the touchpad driver
# to all touchpads. See xorg.conf.d(5) for more information on
# InputClass.
# DO NOT EDIT THIS FILE, your distribution will likely overwrite
# it when updating. Copy (and rename) this file into
# /etc/X11/xorg.conf.d first.
# Additional options may be added in the form of
#   Option "OptionName" "value"
#
Section "InputClass"
        Identifier "touchpad catchall"
        Driver "synaptics"
        MatchIsTouchpad "on"
        Option "TapButton1" "1"
        Option "TapButton2" "2"
        Option "TapButton3" "3"
# This option is recommend on all Linux systems using evdev, but cannot be
# enabled by default. See the following link for details:
# http://who-t.blogspot.com/2010/11/how-to-ignore-configuration-errors.html
        MatchDevicePath "/dev/input/event*"
EndSection

Section "InputClass"
        Identifier "touchpad ignore duplicates"
        MatchIsTouchpad "on"
        MatchOS "Linux"
        MatchDevicePath "/dev/input/mouse*"
        Option "Ignore" "on"
EndSection

# This option enables the bottom right corner to be a right button on
# non-synaptics clickpads.
# This option is only interpreted by clickpads.
Section "InputClass"
        Identifier "Default clickpad buttons"
        MatchDriver "synaptics"
        Option "SoftButtonAreas" "50% 0 82% 0 0 0 0 0"
EndSection

# This option disables software buttons on Apple touchpads.
# This option is only interpreted by clickpads.
Section "InputClass"
        Identifier "Disable clickpad buttons on Apple touchpads"
        MatchProduct "Apple|bcm5974"
        MatchDriver "synaptics"
        Option "SoftButtonAreas" "0 0 0 0 0 0 0 0"
EndSection
EOF

}

function postinstall(){
	USER_NAME=$1
	DESTDIR=$2
	# Specific user configurations

	## Set defaults directories
	chroot ${DESTDIR} su -c xdg-user-dirs-update ${USER_NAME}

	## Unmute alsa channels
	chroot ${DESTDIR} amixer -c 0 set Master playback 100% unmute>/dev/null 2>&1

	# Set gsettings
	cp /arch/set-gsettings ${DESTDIR}/usr/bin/set-gsettings
	mkdir -p ${DESTDIR}/var/run/dbus
	mount -o bind /var/run/dbus ${DESTDIR}/var/run/dbus
	chroot ${DESTDIR} su -c "/usr/bin/set-gsettings" ${USER_NAME} >/dev/null 2>&1
	rm ${DESTDIR}/usr/bin/set-gsettings

	# Fix transmission leftover
	mv ${DESTDIR}/usr/lib/tmpfiles.d/transmission.conf ${DESTDIR}/usr/lib/tmpfiles.d/transmission.conf.backup

	# Configure touchpad
	_set_50-synaptics

	# Set Cinnarch name in filesystem files
	cp /etc/arch-release ${DESTDIR}/etc
	cp -f /etc/os-release ${DESTDIR}/etc/os-release

	# Set Adwaita cursor theme
	chroot ${DESTDIR} ln -s /usr/share/icons/Adwaita /usr/share/icons/default
	
	# Set default MDM theme
    sed -i "s#\[greeter\].*#&\n\nGraphicalTheme=Arc-Brave-Userlist\n\n#" ${DESTDIR}/etc/mdm/custom.conf
}

touch /tmp/.postinstall.lock
postinstall $1 $2
rm /tmp/.postinstall.lock
