#!/usr/bin/env bash
# SO-101 teleop/record helper. Usage: ./so101.sh {teleop|teleop-cam|record} [extra lerobot args...]
set -euo pipefail
cd "$(dirname "$0")/.."
source .venv/bin/activate

FOLLOWER_PORT=/dev/tty.usbmodem5B610341971
LEADER_PORT=/dev/tty.usbmodem5B140309081
CAMERAS="{front: {type: opencv, index_or_path: 0, width: 1280, height: 720, fps: 30}, wrist: {type: opencv, index_or_path: 1, width: 640, height: 480, fps: 30}}"

REPO_ID=${REPO_ID:-willlyb/hampter-pickup}
TASK=${TASK:-put_red_object_in_tupperware}
EPISODES=${EPISODES:-10}
EPISODE_TIME=${EPISODE_TIME:-60}
RESET_TIME=${RESET_TIME:-60}

# second pair, only used when BIMANUAL=1
FOLLOWER_PORT_R=${FOLLOWER_PORT_R:-/dev/tty.usbmodemCHANGEME_R}
LEADER_PORT_R=${LEADER_PORT_R:-/dev/tty.usbmodemCHANGEME_R}

if [ "${BIMANUAL:-0}" = 1 ]; then
  ARMS=(
    --robot.type=bi_so_follower --robot.id=follower
    --robot.left_arm_config.port="$FOLLOWER_PORT"
    --robot.right_arm_config.port="$FOLLOWER_PORT_R"
    --teleop.type=bi_so_leader --teleop.id=leader
    --teleop.left_arm_config.port="$LEADER_PORT"
    --teleop.right_arm_config.port="$LEADER_PORT_R"
  )
else
  ARMS=(
    --robot.type=so101_follower --robot.port="$FOLLOWER_PORT" --robot.id=follower1
    --teleop.type=so101_leader  --teleop.port="$LEADER_PORT"  --teleop.id=leader1
  )
fi

case "${1:-}" in
  teleop)
    shift; lerobot-teleoperate "${ARMS[@]}" "$@" ;;
  teleop-cam)
    shift; lerobot-teleoperate "${ARMS[@]}" --robot.cameras="$CAMERAS" --display_data=true "$@" ;;
  record)
    shift
    # optional task name: ./so101.sh record pos1  -> single_task=pos1
    case "${1:-}" in
      pos*)
        POS=$1; shift
        TASK="hampster_in_tupperware_pos_${POS#pos}"
        ;;
    esac
    # one dataset: create it the first time (no timestamp suffix), append after that
    DATA_DIR="${HF_LEROBOT_HOME:-$HOME/.cache/huggingface/lerobot}/$REPO_ID"
    # resume only if real episodes exist; a bare meta/ stub from an aborted run gets recreated
    if [ -d "$DATA_DIR/data" ]; then
      MODE=(--resume=true)
    else
      rm -rf "$DATA_DIR"
      MODE=(--dataset.no_stamp=true)
    fi
    echo ">> $REPO_ID / task=$TASK / $EPISODES episodes / ${MODE[*]}"

    lerobot-record "${ARMS[@]}" --robot.cameras="$CAMERAS" --display_data=true \
      --dataset.repo_id="$REPO_ID" --dataset.root="$DATA_DIR" --dataset.single_task="$TASK" \
      --dataset.num_episodes="$EPISODES" --dataset.fps=30 \
      --dataset.episode_time_s="$EPISODE_TIME" --dataset.reset_time_s="$RESET_TIME" \
      --dataset.streaming_encoding=true --dataset.encoder_threads=2 \
      --dataset.push_to_hub=true "${MODE[@]}" "$@" ;;
  *)
    echo "usage: $0 {teleop|teleop-cam|record} [extra args]" >&2; exit 1 ;;
esac
