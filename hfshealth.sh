#!/bin/bash

CMD=$(basename $0)
VERSION="1.0.0"

SLACK_ENDPOINT=""
UUID=""
PID_DIR="/usr/local/var/run/hfshealth"

usage() {
  echo "Usage $CMD [OPTIONS] UUID"
  echo "  The $CMD utility verifies HFS file systems by using [fsck_hfs] command line interface inside."
  echo "  Verification will avoid the time machine backup process by waiting until backup will be done."
  echo "  Also, we will lock your disk volume from I/O operations while verification proceeds."
  echo
  echo "Options:"
  echo "  -s, --slack-url"
  echo "    Url of the Slack Webhook endpoint will be used to report the result of verification to your slack channel."
  echo
  echo "  -h, --help"
  echo
  echo "  -v, --version"
}

start_process() {
  if [ ! -d "$PID_DIR" ]; then
    mkdir -p $PID_DIR
  fi

  if [ -e "$PID_FILE" ]; then
    echo "$CMD: Job already in process." 1>&2
    exit 1
  fi

  echo $$ > "$PID_FILE"

  trap end_process exit
}

end_process() {
  unlink "$PID_FILE"
}

# Detect arguments
for OPT in "$@"
do
  case $OPT in
    -h | --help)
      usage
      exit 1
      ;;
    -v | --version)
      echo $VERSION
      exit 1
      ;;
    -s | --slack-url)
      if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "$CMD: option requires an argument -- $1" 1>&2
        exit 1
      fi
      SLACK_ENDPOINT=$2
      shift 2
      ;;
    *)
      if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
        UUID=$1
        shift 1
      fi
      ;;
  esac
done

# Arguments validation
if [ -z "$UUID" ]; then
  echo "$CMD: device UUID is required parameter" 1>&2
  exit 1
fi

# Starting our job...
PID_FILE="$PID_DIR/$UUID.pid"
start_process

# Detect the real device name from UUID identifier
DEVICE=$(diskutil info "$UUID" | grep "Device Node" | awk '{print $3}')

if [ -z "$DEVICE" ]; then
  echo "$CMD: Device was not found." 1>&2
  exit 1
fi

# We have to wait until the time machine job will be done
while :
do
  TIMEMACHINE_STATUS=$(tmutil status | grep -c "Running = 1")

  if [ "$TIMEMACHINE_STATUS" = 0 ]; then
    break;
  fi

  sleep 10s
done

# Now we can start verification process
RESULTS=$(fsck_hfs -nlE "$DEVICE")
STATUS=$?

if [ -z "$SLACK_ENDPOINT" ]; then
  echo "$RESULTS"
else
  COMPUTER_NAME=$(scutil --get ComputerName)

  curl -X POST -H 'Content-type: application/json' --data '{"text": "
*[HFS Health Report]*
Computer: *'"$COMPUTER_NAME"'*
Device: '"$DEVICE"'
Status: '"$STATUS"'
Results:
```
'"$RESULTS"'
```
"}' $SLACK_ENDPOINT >& /dev/null
fi

exit $STATUS
