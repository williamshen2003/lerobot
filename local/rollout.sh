#!/usr/bin/env bash
# Hampter pickup inference. Usage: ./local/rollout.sh [extra lerobot args...]
#   POLICY=... TASK=... DURATION=... ./local/rollout.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source .venv/bin/activate
set -a; source .env; set +a

POLICY=${POLICY:-willlyb/hampter_pickup_act}
TASK=${TASK:-"Pick up the hampter"}
DURATION=${DURATION:-60}

exec lerobot-rollout \
  --strategy.type=base \
  --policy.path="$POLICY" \
  --robot.type=so101_follower \
  --robot.id=follower1 \
  --robot.port="$FOLLOWER_PORT" \
  --robot.cameras="{front: {type: opencv, index_or_path: $FRONT_CAM, width: 1280, height: 720, fps: 30}, wrist: {type: opencv, index_or_path: $WRIST_CAM, width: 640, height: 480, fps: 30}}" \
  --task="$TASK" \
  --duration="$DURATION" \
  "$@"
