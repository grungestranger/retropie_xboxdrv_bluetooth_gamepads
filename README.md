# retropie_xboxdrv_bluetooth_gamepads

Yes, I have not invented anything better than to list the keywords in the title.

This guide will help you to set up your bluetooth gamepads on RetroPie on Raspberry Pi using xboxdrv. Also you can configure your gamepads to joy2key mode to emulate keyboard by gamepad.

## Hardware and software

```
Raspberry Pi 3 Model B
	AC Adapter - Output: 5V, 3000mA
	SD Card - 64GB
RetroPie v4.3 (Pre-made image)
	Xboxdrv v0.8.8
iPega gamepads
	PG-9062S (it has real analog triggers)
	PG-9037 (it has buttons instead triggers)
```

## Manual

### Install Xboxdrv from RetroPie-Setup script

```shell
sudo /home/pi/RetroPie-Setup/retropie_setup.sh
```
Manage packages -> Manage driver packages -> xboxdrv -> Install from binary

Don't enable it. Check `/etc/rc.local` that xboxdrv don't start here.

### Add udev rules

```shell
sudo nano /etc/udev/rules.d/99-bluetooth.rules
```
Paste text from the accordingly file.

If you've already set up udev rules in bluetooth settings (Configuration / tools -> bluetooth -> Set up udev rule for Joypad (...) -> your gamepad). And `/etc/udev/rules.d/99-bluetooth.rules` contains the line like that:
```
SUBSYSTEM=="input", ATTRS{name}=="PG-9062S", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1"
```
You must remove this line to games can see only virtual input devices that xboxdrv will create.

Replace PG-9062S & PG-9037 on your gamepads' names.

If name of your gamepad contains spaces, the text should be like that:
```
ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="gamepad 1", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad1", RUN+="/bin/systemctl --no-block start gamepads@gamepad1.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{name}=="gamepad 1", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad1"
```

If your gamepads have the same name, you need to know `ATTRS{uniq}` of them. We can to see `ATTRS{name}` and `ATTRS{uniq}` here:
```shell
cat /proc/bus/input/devices
```
or (see event's number in the line "Handlers" - in results of the previous command):
```shell
udevadm info -a -n /dev/input/event<event's number>
```
And the text should be like that:
```
ACTION=="add", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 1 uniq>", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad1", RUN+="/bin/systemctl --no-block start gamepads@gamepad1.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 1 uniq>", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad1"
ACTION=="add", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 2 uniq>", ENV{DEVNAME}=="/dev/input/event*", SYMLINK+="input/gamepad2", RUN+="/bin/systemctl --no-block start gamepads@gamepad2.service"
ACTION=="remove", SUBSYSTEM=="input", ATTRS{uniq}=="<gamepad 2 uniq>", RUN+="/home/pi/gamepads.sh gamepadDisconnect gamepad2"
```

### Add systemctl service

Since we cannot to run a long script in the `RUN` attribute in udev rules we run systemctl service when the gamepad connects.

Create file:
```shell
sudo nano /etc/systemd/system/gamepads@.service
```
Paste text from the accordingly file.

### Create onstart and onend scripts

Create files that help configure controllers for different games (ports):
```shell
nano /opt/retropie/configs/all/runcommand-onstart.sh
```
Paste text from the accordingly file.<br>
and:
```shell
nano /opt/retropie/configs/all/runcommand-onend.sh
```
Paste text from the accordingly file.

Add execute permissions:
```shell
chmod +x /opt/retropie/configs/all/runcommand-onstart.sh \
/opt/retropie/configs/all/runcommand-onend.sh
```

### Create the main script

Create file:
```shell
nano /home/pi/gamepads.sh
```
Paste text from the accordingly file.

Add execute permissions:
```shell
chmod +x /home/pi/gamepads.sh
```

You need to know the names of all buttons and axis of your gamepads. For that:
```shell
evtest /dev/input/event<event's number>
```
Click the buttons and you will see their names.

Replace gamepads' and games' settings to your own settings. Use names of gamepads and games that passes to this script.

Restart system and enjoy!
```shell
sudo reboot
```
