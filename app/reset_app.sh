#!/bin/bash

DOCKER_CONTAINER_NAME="test-mongo"

MONGO_DATABASE="app_db"
MONGO_COLLECTION="entities"

# exit if a command exits with a non-zero status
set -e
# redeploy smart contracts
python3 scripts/deploy.py > /dev/null
# drop the collection
docker exec -it "$DOCKER_CONTAINER_NAME" mongosh "$MONGO_DATABASE" --eval "db.getCollection('$MONGO_COLLECTION').drop()" > /dev/null