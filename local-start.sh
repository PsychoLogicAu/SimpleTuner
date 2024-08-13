#!/usr/bin/env bash

source /opt/venv/bin/activate

cd /workspace/SimpleTuner

echo "Link training config file to config/config.json, then"
echo "$ env ENV=default CONFIG_BACKEND=env bash train.sh"

exec /usr/bin/bash
