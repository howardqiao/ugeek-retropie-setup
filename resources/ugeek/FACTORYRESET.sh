#!/bin/bash
if [ ! -d "/home/pi/ugeek-retropie-setup" ]; then
	cd /home/pi/
	git clone https://github.com/howardqiao/ugeek-retropie-setup.git --depth 1
fi
cd /home/pi/ugeek-retropie-setup
sudo ./setup.sh