# HeatMiser NeoHub rebooter

Hi! This repository contains a Bash shell script that, when ran on a daily basis, reboots [Heatmiser's NeoHub](https://www.heatmiser.com/en/neohub-smart-control/) (v2) to keep the legacy API available that normally stops listening after a 48 hour idle period. More specifically, this keeps the Apple HomeKit integration working.

In short, the script:

- Checks connectivity to the NeoHub and inform through push notification if it fails to connect
- Reboots the NeoHub
- Verifies the reboot succeeded by checking the uptime

## Prerequisites

- A recent version of [NodeJS](https://nodejs.org). It's recommended to use a Node version switcher like [nvm](https://github.com/nvm-sh/nvm).
- The script currently depends on the [Pushover](http://pushover.net) web+app solution for easy push notification delivery. Specify the user and app token in the top config part of the script.

## Install instructions

- First, run `npm install` to install wscat - a Node module that supports connecting to websockets and reading/writing them.
- Configure the script by setting:
	- HUB_IP
	- HUB_TOKEN
	- PUSHOVER_API_TOKEN
	- PUSHOVER_USER_KEY
- Run `crontab -e` to edit your crontab.
- Add a line defining the `PATH` envvar; ensure node / wscat can be found on this path.
- Add a line defining the `SHELL` to be bash: `SHELL=/bin/bash`
- Add the actual cron definition: e.g.
	- `0 1 * * *  /path/to/restart_neohub.sh >> /logpath/restart_neohub.log`

That's it!
