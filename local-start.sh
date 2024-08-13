#!/usr/bin/env bash

source /opt/venv/bin/activate

cd /workspace/SimpleTuner

echo "Link training config file to config/config.json, then"
echo "$ env ENV=default CONFIG_BACKEND=env SIMPLETUNER_LOG_LEVEL=DEBUG bash simpletuner/train.sh"

exec /usr/bin/bash
