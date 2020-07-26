# Description

This utility verifies HFS file systems by using `fsck_hfs` command line interface inside.
Verification will avoid the time machine backup process by waiting until backup will be done.
Also, we will lock your disk volume from I/O operations while verification proceeds.

**NOTE: This utility was designed for MacOS and works with bash shells only.**

# Notices

The shell script not maintained or supported by the developer. It was made for personal use only,
so please don't use it on production or commercial platforms.
There is no warranty in any cases.
  
This script was made for automating the volume structure verification, 
and notify an administrator about any problems was found for.  
We will not try to fix any problems automatically, cause in some cases it will exacerbate the problem.

# Installation

```bash
wget -O /usr/local/bin/hfshealth https://raw.githubusercontent.com/timoshka-lab/hfshealth/master/hfshealth.sh
chmod +x /usr/local/bin/hfshealth
```

# Usage

## Basic syntax

```bash
sudo hfshealth [OPTIONS] {Volume UUID}
```

### Usage with options

Simply, verify the health of your volume and get results as stdout.

```bash
sudo hfshealth 7DFCEB10-F686-3834-A903-8E61D9CBAC03
```

Also, you can send verification results into your slack channel.
For specific instructions about Slack webhooks API, please check [this article](https://api.slack.com/messaging/webhooks).

```bash
sudo hfshealth --slack-url https://hooks.slack.com/services/XXXXXX/XXXXXX/XXXXXX 7DFCEB10-F686-3834-A903-8E61D9CBAC03
```

### Working with cron scheduling

At first, you have to open the crontab settings as root user. Without root user privileges, `fsck_hfs` command won't work fine.

```bash
sudo crontab -e
```

Next, we have to include some path which we use inside the shell script.

```crontab
PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Run hfs verification every day at midnight
0 0 * * * /usr/local/bin/hfshealth --slack-url https://hooks.slack.com/services/XXXXXX/XXXXXX/XXXXXX 7DFCEB10-F686-3834-A903-8E61D9CBAC03
```

### The way to find your volume UUID

You can find the UUID easily by using `diskutil` command.
If you don't know you device identifier, you can find it by `diskutil list` command, which will list all disks on your system.
The volume identifier will be looked like `disk4s2`.

```bash
diskutil info /dev/diskXXX | grep "Volume UUID"
```

### Why UUID ?

`fsck_hfs` was designed to work with device identifier which can be changed by replacing your storage disk to another USB or Thunderlot device.
So, it won't be safe to use the device identifier for scheduling verification jobs at background system.  
My first purpose of this script was to make it work with the Volume UUID instead of identifier.
