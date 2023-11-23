# pi-simple-radio
Raspberry Pi radio with integrated BT speaker

# Details
This project uses a Raspberry Pi running 32bit Raspbian OS.

The hardware consists of:
- Raspberry Pi (I am using a 3 but a Zero would probably do)
- BlueTooth speaker
- Pushbutton with integral LED
- Digital rotary encoder with integral 3 colour LED ("RGB Encoder Breakout" by Pimoroni)

The software requires vlc and mpg123 to be installed.

I run the software as a service, in which case the Pi needs to be set to auto-login at the console. The program needs to be launched after these commands:
systemctl --user start pulseaudio
bluetoothctl connect <id for BT speaker>
