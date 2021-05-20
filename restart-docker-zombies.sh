#!/bin/bash

while getopts l:e: flag; do
  case "${flag}" in
  l) LIMIT=${OPTARG} ;;
  e) EXCLUDED_STR=${OPTARG} ;;
  esac
done
export EXCLUDED_STR
export LIMIT

# arg1=container_id
restart_container() {
  CONTAINER_ID="$1"
  CMD=$(sudo docker restart "$CONTAINER_ID")
  echo "$CMD"
}

# arg1=container_id, arg2=metric
extract_uptime_from_string() {
  CONTAINER_ID="$1"
  METRIC="$2"
  UPTIME=$(echo "$METRIC" | grep -o -E '[0-9]+' | head -1 | sed -e 's/^0\+//')

  if [[ "$METRIC" == *"second"* ]]; then
    return
  fi

  if [[ "$METRIC" == *"hour"* ]]; then
    restart_container $CONTAINER_ID
    return
  fi

  if [[ "$UPTIME" -gt $LIMIT ]]; then
    restart_container $CONTAINER_ID
    return
  fi
}

# arg1=container_id
container_excluded() {
  CONTAINER_ID="$1"
  IFS=', ' read -r -a EXCLUDED_ARR <<< "$EXCLUDED_STR"
  NAME=$(sudo docker ps --filter id="$CONTAINER_ID" --format "{{.Names}}: {{.Command}}")
  for EXCLUDED in "${EXCLUDED_ARR[@]}"; do
    :
    if [[ "$NAME" == *"$EXCLUDED:"* ]]; then
      return 0
    fi
  done
  return 1
}

# arg1=container_id
read_container_metrics() {
  CONTAINER_ID="$1"
  METRICS=$(sudo docker ps --filter id="$CONTAINER_ID" --format "{{.Status}}: {{.Command}}")
  echo "$METRICS" | while read -r METRIC; do
    extract_uptime_from_string "$CONTAINER_ID" "$METRIC"
  done
}

get_container_ids() {
  IDS=$(sudo docker-compose ps -q)
  echo "$IDS" | while read -r ID; do
    if container_excluded "$ID"; then
      continue
    fi
    read_container_metrics "$ID"
  done
}

get_container_ids
