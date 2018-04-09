#!/bin/bash
FONT_URL="https://github.com/adobe-fonts/source-han-sans/raw/release/OTC/SourceHanSans-Bold.ttc"
FONT_FILE="/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc"
FONT_SIZE="0.055"
FILE_CONFIG="/boot/config.txt"
FILE_RCLOCAL="/etc/rc.local"
FILE_MODULES="/etc/modules"
FILE_RETROARCH="/opt/retropie/configs/all/retroarch.cfg"
FILE_ESINPUT="/opt/retropie/configs/all/emulationstation/es_input.cfg"

function software_update(){
	echo "]Update System["
	SOFT=$(dpkg -l python-dev python-pip python-smbus | grep "<none>")
	if [ -n "$SOFT" ]; then
		apt update
		apt -y install python-dev python-pip python-smbus
	else
		echo "python-dev python-pip python-smbus install complete."
	fi
	SOFT=$( pip search evdev | grep "INSTALLED")
	if [ -z "$SOFT" ]; then
		pip install evdev
	else
		echo "python-evdev install complete!"
	fi
}
function disable_input(){
	sed -i '/^dtparam=i2c_arm/d' $FILE_CONFIG
	sed -i '/^i2c-dev/d' $FILE_MODULES
	sed -i '/joyBonnet.py/d' $FILE_RCLOCAL
	if [ -e "/boot/joyBonnet.py" ]; then
		rm /boot/joyBonnet.py
	fi
	if [ -e "/etc/udev/rules.d/10-retrogame.rules" ]; then
		rm /etc/udev/rules.d/10-retrogame.rules
	fi
}
function enable_input(){
	echo "dtparam=i2c_arm=on" >> $FILE_CONFIG
	sed -i '/^exit 0/icd \/boot;python joyBonnet.py &' $FILE_RCLOCAL
	if [ -e "/boot/joyBonnet.py" ]; then
		rm /boot/joyBonnet.py
	fi
	cp resources/joyBonnet.py /boot/
	echo "i2c-dev" >> $FILE_MODULES
	touch /etc/udev/rules.d/10-retrogame.rules
	echo "SUBSYSTEM==\"input\", ATTRS{name}==\"retrogame\", ENV{ID_INPUT_KEYBOARD}=\"1\"" > /etc/udev/rules.d/10-retrogame.rules
}
function config_input(){
	echo ">Config input"
	disable_input
	enable_input
}
function disable_sound(){
	sed -i '/^dtparam=audio/d' $FILE_CONFIG
	echo "dtparam=audio=on" >> $FILE_CONFIG
	sed -i '/^dtparam=hifiberry-dac/d' $FILE_CONFIG
	sed -i '/^dtparam=i2s-mmap/d' $FILE_CONFIG
	if [ -e "/etc/asound.conf" ]; then
		rm /etc/asound.conf
	fi
}
function enable_sound(){
	sed -i '/^dtparam=audio/d' $FILE_CONFIG
	cat << EOF >> $FILE_CONFIG
dtparam=audio=off
dtoverlay=hifiberry-dac
dtoverlay=i2s-mmap
EOF
	if [ -e "/etc/asound.conf" ]; then
		rm /etc/asound.conf
	else
		touch /etc/asound.conf
	fi
	cat << EOF > /etc/asound.conf
pcm.speakerbonnet {
   type hw card 0
}

pcm.dmixer {
   type dmix
   ipc_key 1024
   ipc_perm 0666
   slave {
     pcm "speakerbonnet"
     period_time 0
     period_size 1024
     buffer_size 8192
     rate 44100
     channels 2
   }
}

ctl.dmixer {
    type hw card 0
}

pcm.softvol {
    type softvol
    slave.pcm "dmixer"
    control.name "PCM"
    control.card 0
}

ctl.softvol {
    type hw card 0
}

pcm.!default {
    type             plug
    slave.pcm       "softvol"
}
EOF
}
function config_sound(){
	echo ">Config Sound"
	disable_sound
	enable_sound
}
function disable_screen(){
	sed -i '/^dtparam=spi/d' $FILE_CONFIG
	sed -i '/^dtoverlay=pitft22/d' $FILE_CONFIG
	sed -i '/^hdmi_group=/d' $FILE_CONFIG
	sed -i '/^hdmi_mode=/d' $FILE_CONFIG
	sed -i '/^hdmi_cvt=/d' $FILE_CONFIG
	sed -i '/^hdmi_force_hotplug=/d' $FILE_CONFIG
	#sed -i '/^sh -c "TERM=linux/d' $FILE_RCLOCAL
}
function enable_screen(){
	#sed -i '/^exit 0/ish -c "TERM=linux setterm -blank 0 >/dev/tty0"' $FILE_RCLOCAL
	cat << EOF >> $FILE_CONFIG
dtparam=spi=on
dtoverlay=pitft22,speed=80000000,rotate=270,fps=60
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0
hdmi_force_hotplug=1
EOF
}
function config_screen(){
	echo ">Config Screen"
	disable_screen
	enable_screen
}
function config_emulationstation(){
	echo "]Config EmulationStation["
	echo ">Download Font"
	if [ ! -e "/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc" ]; then
		#curl -LJ0 -o $FONT_FILE $FONT_URL
		cp resources/SourceHanSans-Bold.ttc $FONT_FILE
	fi
	
	echo ">Change font of emulationstatoin"
	sed -i -e 's/Cabin-Bold.ttf/SourceHanSans-Bold.ttc/g' /etc/emulationstation/themes/carbon/carbon.xml
	echo ">Change font size of EmulationStation"
	sed -i -e "s/<fontSize>.*<\/fontSize>/<fontSize>$FONT_SIZE<\/fontSize>/g" /etc/emulationstation/themes/carbon/carbon.xml
	echo ">Add UGEEK Theme in EmulationStation"
	if [ -d "/etc/emulationstation/themes/carbon/ugeek" ]; then
		echo "remove old folder"
		rm -rf /etc/emulationstation/themes/carbon/ugeek
	fi
	cp -a resources/themes/ugeek /etc/emulationstation/themes/carbon/
	echo ">Add UGEEK System in EmulationStation"
	if [ -d "/home/pi/RetroPie/ugeek" ]; then
		echo "remove old folder"
		rm -rf /home/pi/RetroPie/ugeek
	fi
	cp -a resources/ugeek /home/pi/RetroPie
	chown -R pi:pi /home/pi/RetroPie
	IN_SYSTEM=$(cat /etc/emulationstation/es_systems.cfg | grep UGEEK)
	if [ -z "$IN_SYSTEM" ]; then
		sed -i -e '/<systemList>/r patches/es_system.cfg' /etc/emulationstation/es_systems.cfg
	fi
	#cp /opt/retropie/configs/all/emulationstation/es_input.cfg.bak /opt/retropie/configs/all/emulationstation/es_input.cfg
	#sed -i -e '/inputAction>/r patches/es_input.cfg' /opt/retropie/configs/all/emulationstation/es_input.cfg
	if [ -e "$FILE_ESINPUT" ]; then
		rm $FILE_ESINPUT
	fi
	touch $FILE_ESINPUT
	cat << EOF >> $FILE_ESINPUT
<?xml version="1.0"?>
<inputList>
  <inputAction type="onfinish">
    <command>/opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh</command>
  </inputAction>
  <inputConfig type="keyboard" deviceName="Keyboard" deviceGUID="-1">
    <input name="pageup" type="key" id="50" value="1"/>
    <input name="start" type="key" id="13" value="1"/>
    <input name="up" type="key" id="1073741906" value="1"/>
    <input name="a" type="key" id="1073742048" value="1"/>
    <input name="b" type="key" id="1073742050" value="1"/>
    <input name="down" type="key" id="1073741905" value="1"/>
    <input name="pagedown" type="key" id="49" value="1"/>
    <input name="right" type="key" id="1073741903" value="1"/>
    <input name="x" type="key" id="122" value="1"/>
    <input name="select" type="key" id="32" value="1"/>
    <input name="y" type="key" id="120" value="1"/>
    <input name="left" type="key" id="1073741904" value="1"/>
  </inputConfig>
</inputList>
EOF
}
function config_retroarch(){
	echo ">Config Retroarch"
	sed -i '/^#*[ ]*audio_out_rate/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_exit_emulator/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_state_slot_increase/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_state_slot_decrease/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_reset/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_menu_toggle/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_enable_hotkey/d' $FILE_RETROARCH
	
	echo "audio_out_rate = 44100" >> $FILE_RETROARCH
	echo 'input_exit_emulator = "enter"' >> $FILE_RETROARCH
	echo 'input_state_slot_increase = "right"' >> $FILE_RETROARCH
	echo 'input_state_slot_decrease = "left"' >> $FILE_RETROARCH
	echo 'input_reset = "alt"' >> $FILE_RETROARCH
	echo 'input_menu_toggle = "z"' >> $FILE_RETROARCH
	echo 'input_enable_hotkey = "space"' >> $FILE_RETROARCH
	
	sed -i '/^#*[ ]*input_player1_a/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_b/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_y/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_x/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_start/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_select/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_l/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_r/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_left/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_right/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_up/d' $FILE_RETROARCH
	sed -i '/^#*[ ]*input_player1_down/d' $FILE_RETROARCH
	
	echo 'input_player1_a = "ctrl"' >> $FILE_RETROARCH
	echo 'input_player1_b = "alt"' >> $FILE_RETROARCH
	echo 'input_player1_y = "x"' >> $FILE_RETROARCH
	echo 'input_player1_x = "z"' >> $FILE_RETROARCH
	echo 'input_player1_start = "enter"' >> $FILE_RETROARCH
	echo 'input_player1_select = "space"' >> $FILE_RETROARCH
	echo 'input_player1_l = "num2"' >> $FILE_RETROARCH
	echo 'input_player1_r = "num1"' >> $FILE_RETROARCH
	echo 'input_player1_left = "left"' >> $FILE_RETROARCH
	echo 'input_player1_right = "right"' >> $FILE_RETROARCH
	echo 'input_player1_up = "up"' >> $FILE_RETROARCH
	echo 'input_player1_down = "down"' >> $FILE_RETROARCH
}
function disable_raspi2fb(){
	systemctl stop raspi2fb@1.service
	systemctl disable raspi2fb@1
	if [ -e "/etc/systemd/system/raspi2fb@.service" ]; then
		rm /etc/systemd/system/raspi2fb@.service
	fi
	systemctl daemon-reload
	if [ -e "/usr/local/bin/raspi2fb" ]; then
		rm /usr/local/bin/raspi2fb
	fi
}
function enable_raspi2fb(){
	cp resources/raspi2fb /usr/local/bin/
	cp resources/raspi2fb@.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable raspi2fb@1.service
	systemctl start raspi2fb@1
}
function config_raspi2fb(){
	echo ">Config Raspi2fb"
	disable_raspi2fb
	enable_raspi2fb
}
function main(){
	software_update
	config_emulationstation
	config_screen
	config_raspi2fb
	config_input
	config_sound
	config_retroarch
	echo ">Complete!<"
}
main
reboot
