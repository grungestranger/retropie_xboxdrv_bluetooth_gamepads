retropie_xboxdrv_bluetooth_gamepads
===================================

Yes, I have not invented anything better than to list the keywords in the title.

This guide will help you to set up your bluetooth gamepads on RetroPie on Raspberry Pi using xboxdrv. Also you can configure your gamepads to joy2key mode to emulate keyboard by gamepad.

Hardware and software
---------------------

Raspberry Pi 3 Model B
	AC Adapter - Output: 5V, 3000mA
	SD Card - 64GB
RetroPie v4.3 (Pre-made image)
	Xboxdrv v0.8.8
iPega gamepads
	PG-9062S (it has real analog triggers)
	PG-9037 (it has buttons instead triggers)

Manual
------

### Install Xboxdrv from RetroPie-Setup script
```shell
sudo /home/pi/RetroPie-Setup/retropie_setup.sh
```
Manage packages -> Manage driver packages -> xboxdrv -> Install from binary
Don't enable it. Check /etc/rc.local that xboxdrv don't start here.

### Add udev rules
```shell
sudo nano /etc/udev/rules.d/99-bluetooth.rules
```
Paste text from the accordingly file.
- If you've already set up udev rules in bluetooth settings
- (Configuration / tools -> bluetooth -> Set up udev rule for Joypad (...) -> <gamepad>)
- And /etc/udev/rules.d/99-bluetooth.rules contains the line like that:
`
SUBSYSTEM=="input", ATTRS{name}=="PG-9062S", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
`
- You must remove this line to games can see only xboxdrv's devices.
- Replace PG-9062S & PG-9037 on your gamepads' names
- If name of your gamepad contains spaces, the text should be like that:
`
ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="gamepad 1", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad1", RUN+="/bin/systemctl --no-block start gamepads@gamepad1.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{name}=="gamepad 1", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad1"
`
- If your gamepads have the same name, you need to know ATTRS{uniq} of them
- We can to see ATTRS{name} and ATTRS{uniq} here:
```shell
cat /proc/bus/input/devices
```
- or (see event's number in the line "Handlers" - in results of the previous command)
```shell
udevadm info -a -n /dev/input/event<event's number>
```
- And the text should be like that:
`
ACTION=="add", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 1 uniq>", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad1", RUN+="/bin/systemctl --no-block start gamepads@gamepad1.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 1 uniq>", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad1"
ACTION=="add", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 2 uniq>", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad2", RUN+="/bin/systemctl --no-block start gamepads@gamepad2.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 2 uniq>", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad2"
`

### Add systemctl service
Since we cannot to run a long script in the RUN attribute in udev rules we run systemctl service when the gamepad connects.
```shell
sudo nano /etc/systemd/system/gamepads@.service
```
Paste text from the accordingly file.


### To configure controllers for different games (ports)
create files
```shell
nano /opt/retropie/configs/all/runcommand-onstart.sh
```
Paste text from the accordingly file.

and
```shell
nano /opt/retropie/configs/all/runcommand-onend.sh
```
Paste text from the accordingly file.

Add execute permissions
```shell
chmod +x /opt/retropie/configs/all/runcommand-onstart.sh \
/opt/retropie/configs/all/runcommand-onend.sh
```

### Create the main file

You need to know the names of all buttons and axis of your gamepad. For that:
```shell
evtest /dev/input/event<event's number>
```
Click the buttons and you will see their names.

Create file:
```shell
nano /home/pi/gamepads.sh
```
Paste text from the accordingly file.

Add execute permissions
```shell
chmod +x /home/pi/gamepads.sh
```

Replace gamepads' settings and games' settings to your own settings. Use names of gamepads from /etc/udev/rules.d/99-bluetooth.rules If the names contain spaces or gamepads have the same name then [...RUN+="/bin/systemctl --no-block start gamepads@<this name>.service"...] else [...ATTRS{name}=="<this name (or names)>"...].

Restart system and enjoy!
```shell
sudo reboot
```




























