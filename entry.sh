#!/bin/bash
source SimpleTuner/.venv/bin/activate
echo "$ env ENV=default CONFIG_BACKEND=env bash train.sh"
if [ "$1" = "bash" ] || [ "$1" = "/bin/bash" ]; then
    exec /bin/bash
else
    exec SimpleTuner/train.sh "$@"
fi
