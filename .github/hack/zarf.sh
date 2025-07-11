#!/usr/bin/env bash

set -euo pipefail

declare -A TYPES=("upstream")

for flavor in "${TYPES[@]}"; do
  export IMAGES=`zarf dev find-images --flavor $flavor --skip-cosign ./zarf.yaml 2>/dev/null | yq '.components[] | select(.name == "operator") | .images'`

  echo $IMAGES
done
