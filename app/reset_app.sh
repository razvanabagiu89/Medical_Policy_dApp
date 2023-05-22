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
docker exec -it "$DOCKER_CONTAINER_NAME" mongosh "$MONGO_DATABASE" --eval "db.getCollection('$MONGO_COLLECTION').insertOne({username: 'admin', password: '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', ID: 0})" > /dev/null