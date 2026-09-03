#!/bin/bash
set -a; source "$(dirname "$0")/../.env"; set +a
exec lerobot-train --dataset.repo_id=willlyb/hampter-pickup --policy.type=act --policy.repo_id=willlyb/hampter_pickup_act --policy.private=true --save_checkpoint_to_hub=true --wandb.enable=true --job.target=a10g-large --job.detach=true
