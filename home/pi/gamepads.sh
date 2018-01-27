#!/bin/bash

# $1 - action, $2 - action's parametr

# base settings
base="/opt/retropie/supplementary/xboxdrv/bin/xboxdrv > /dev/null 2>&1
	--evdev /dev/input/\"\$gamepad\"
	--silent
	--detach-kernel-driver
	--force-feedback
	--deadzone-trigger 15%
	--deadzone 4000
	--mimic-xpad
	--device-name \"xboxdrv \$gamepad\"
	--axismap -Y1=Y1,-Y2=Y2"

# gamepads settings
declare -A gamepads
gamepads['PG-9062S']="--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_Z=x2,ABS_RZ=y2,ABS_BRAKE=lt,ABS_GAS=rt,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y
	--evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_NORTH=x,BTN_WEST=y,BTN_TL=lb,BTN_TR=rb,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_SELECT=back,BTN_START=start
	--trigger-as-button
	--device-usbid 0:0:0:0"
gamepads['PG-9037']="--evdev-absmap ABS_X=x1,ABS_Y=y1,ABS_Z=x2,ABS_RZ=y2,ABS_HAT0X=dpad_x,ABS_HAT0Y=dpad_y
	--evdev-keymap BTN_SOUTH=a,BTN_EAST=b,BTN_NORTH=x,BTN_WEST=y,BTN_TL=lb,BTN_TR=rb,BTN_TL2=lt,BTN_TR2=rt,BTN_THUMBL=tl,BTN_THUMBR=tr,BTN_SELECT=back,BTN_START=start
	--trigger-as-button
	--device-usbid 0:0:0:1"

# games settings; games - it's ports for which we need add joy2key settings
declare -A games
games['quake3']="--ui-axismap x2=REL_X:20,y2=REL_Y:20
	--ui-buttonmap tl=BTN_LEFT,tr=BTN_RIGHT
	--ui-axismap x1=KEY_A:KEY_D,y1=KEY_W:KEY_S
	--ui-buttonmap a=KEY_END,b=KEY_RIGHTBRACE,x=KEY_LEFTBRACE,y=KEY_TAB,lb=KEY_LEFTSHIFT,rb=KEY_C,lt=KEY_SPACE,rt=KEY_LEFTCTRL,start=KEY_ENTER,back=KEY_ESC
	--ui-buttonmap du=KEY_UP,dd=KEY_DOWN,dl=KEY_LEFT,dr=KEY_RIGHT"

# kill proc; use global var gamepad
kill_proc () {
	# stop service for correct ending; if it is not running, it doesn't matter
	systemctl --no-block stop gamepads@"$gamepad".service > /dev/null 2>&1
	# kill xboxdrv
	kill `ps -o pid= --ppid \`cat /tmp/gamepad_"$gamepad"\`` > /dev/null 2>&1
}

# read game file and write global variables
read_game_file () {
	if [[ -f /tmp/game ]]; then
		runGame=`sed -n '1p' /tmp/game`
		runGamepad=`sed -n '2p' /tmp/game`
	else
		runGame=null
		runGamepad=null
	fi
}

# check action
case $1 in
"gamepadConnect")
	if [[ -n ${gamepads[$2]} ]]; then
		gamepad=$2
		# waiting creation symlink
		while ! [[ -L /dev/input/$2 ]]; do sleep 1; done
		# write pid to file
		echo "$$" > /tmp/gamepad_"$gamepad"
		#
		read_game_file
		#
		if [[ -n ${games[$runGame]} && $runGamepad = 'null' ]]; then
			# write gamepad's name to game file
			echo -e "$runGame\n$gamepad" > /tmp/game
			# start xboxdrv
			eval $base ${gamepads[$gamepad]} ${games[$runGame]}
		else
			# start xboxdrv
			eval $base ${gamepads[$gamepad]}
		fi
	fi
;;
"gamepadDisconnect")
	if [[ -n ${gamepads[$2]} ]]; then
		gamepad=$2
		#
		kill_proc
		# remove temp gamepad file
		rm /tmp/gamepad_"$gamepad" > /dev/null 2>&1
		#
		read_game_file
		#
		if [[ $gamepad = $runGamepad ]]; then
			# write runGamepad = null to game file
			echo -e "$runGame\n"null > /tmp/game
		fi
	fi
;;
"gameStart")
	if [[ -n ${games[$2]} ]]; then
		game=$2
		# select gamepad
		priorityGamepad='PG-9062S'
		if [[ -f /tmp/gamepad_$priorityGamepad && -n ${gamepads[$priorityGamepad]} ]]; then
			gamepad=$priorityGamepad
		else
			gamepad=null
			for file in `find /tmp/ -name 'gamepad_*' -type f`; do
				str=${file/'/tmp/gamepad_'/}
				if [[ -n ${gamepads[$str]} ]]; then
					gamepad=$str
					break
				fi
			done
		fi
		# write names of game and gamepad to file
		echo -e "$game\n$gamepad" > /tmp/game
		#
		if [[ $gamepad != 'null' ]]; then
			#
			kill_proc
			# write pid to file
			echo "$$" > /tmp/gamepad_"$gamepad"
			# start xboxdrv
			eval $base ${gamepads[$gamepad]} ${games[$game]}
		fi
	fi
;;
"gameStop")
	if [[ -n ${games[$2]} ]]; then
		#
		read_game_file
		# remove temp game file
		rm /tmp/game > /dev/null 2>&1
		#
		if [[ -n ${gamepads[$runGamepad]} ]]; then
			gamepad=$runGamepad
			#
			kill_proc
			# write pid to file
			echo "$$" > /tmp/gamepad_"$gamepad"
			# start xboxdrv
			eval $base ${gamepads[$gamepad]}
		fi
	fi
;;
*)
	echo 'invalid option'
;;
esac
