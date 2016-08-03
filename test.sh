#!/bin/bash

# A test script for trying out your firebase proxy
HOST='YOUR_PROXY_HOST'      # if you launch it locally, it will be http://localhost:9000
DEVICE_ID='YOUR_DEVICE_ID'
ACCESS_TOKEN='YOUR_PARTICLE_ACCESS_TOKEN'
EVENT_TYPE='value'        # 'value', 'child_added', 'child_changed' or 'child_removed'
FIREBASE_PATH='YOUR_FIREBASE_DATABASE_PATH'

curl $HOST -H "Content-Type: application/json" -X POST -d @- <<EOF
{ "device_id" : "$DEVICE_ID", "access_token" : "$ACCESS_TOKEN", "event_type" : "$EVENT_TYPE", "firebase_path" : "$FIREBASE_PATH" }
EOF
