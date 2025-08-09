#!/bin/bash
source SimpleTuner/.venv/bin/activate
if [ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]; then
    exec /bin/bash
else
    exec SimpleTuner/train.sh "$@"
fi
