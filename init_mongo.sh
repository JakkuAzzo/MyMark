#!/bin/bash
set -e

echo "Creating local data folders..."
mkdir -p "$(pwd)/data/users_db" "$(pwd)/data/social_db" "$(pwd)/blockchain/ganache-db"

# Remove any existing mongod lock files to avoid startup errors.
LOCK_USERS="$(pwd)/data/users_db/mongod.lock"
LOCK_SOCIAL="$(pwd)/data/social_db/mongod.lock"
if [ -f "$LOCK_USERS" ]; then
  echo "Removing existing lock file in users_db..."
  rm -f "$LOCK_USERS"
fi
if [ -f "$LOCK_SOCIAL" ]; then
  echo "Removing existing lock file in social_db..."
  rm -f "$LOCK_SOCIAL"
fi

# Check and free port 27017 if in use.
PID_USERS=$(lsof -ti tcp:27017)
if [ -n "$PID_USERS" ]; then
  echo "Port 27017 is in use by process(es): $PID_USERS. Killing them..."
  kill -9 $PID_USERS
fi

# Check and free port 27018 if in use.
PID_SOCIAL=$(lsof -ti tcp:27018)
if [ -n "$PID_SOCIAL" ]; then
  echo "Port 27018 is in use by process(es): $PID_SOCIAL. Killing them..."
  kill -9 $PID_SOCIAL
fi

# Allow time for ports to be freed.
sleep 2

# Check for required database files. If missing, run generate_db.py.
if [ ! -f "$(pwd)/data/users_db/users.db" ] || [ ! -f "$(pwd)/data/social_db/social.db" ]; then
  echo "Required database file(s) not found. Running generate_db.py..."
  python generate_db.py
fi

# Allow time for database files to be created.
sleep 2

DEBUG_MODE=${DEBUG:-false}
if [ "$DEBUG_MODE" = "true" ]; then
  echo "Running in debug mode: starting MongoDB without --fork..."
  echo "Starting MongoDB for users on port 27017..."
  mongod --dbpath "$(pwd)/data/users_db" --port 27017 --logpath users.log
  echo "Starting MongoDB for social media on port 27018..."
  mongod --dbpath "$(pwd)/data/social_db" --port 27018 --logpath social.log
else
  echo "Starting MongoDB for users on port 27017..."
  mongod --dbpath "$(pwd)/data/users_db" --port 27017 --fork --logpath users.log || { echo "Error starting users DB, check users.log:"; cat users.log; exit 1; }
  echo "Starting MongoDB for social media on port 27018..."
  mongod --dbpath "$(pwd)/data/social_db" --port 27018 --fork --logpath social.log || { echo "Error starting social DB, check social.log:"; cat social.log; exit 1; }
fi

sleep 3

echo "Creating collections with schema validation..."

# For User DB (mymark_users_db): Drop and re-create the "users" collection with a JSON schema.
mongo --port 27017 --eval '
db = db.getSiblingDB("mymark_users_db");
db.users.drop();
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["face_embedding", "pass_salt", "pass_hash", "kyc_id_hash", "created_at"],
      properties: {
        face_embedding: {
          bsonType: "binData",
          description: "Must be a binary of 512 bytes (128-D FaceNet vector, little-endian Float32s)"
        },
        pass_salt: {
          bsonType: "string",
          pattern: "^[0-9a-fA-F]{32}$",
          description: "16 random bytes encoded as hex (32 hex characters)"
        },
        pass_hash: {
          bsonType: "string",
          description: "Hash computed by Argon2id(pass + salt)"
        },
        kyc_id_hash: {
          bsonType: "string",
          description: "SHA-256 hash of the ID doc face region (no photo stored)"
        },
        created_at: {
          bsonType: "date",
          description: "Creation date"
        }
      }
    }
  }
});
'

# For Social DB (mymark_social_db): Drop and re-create the collections.
mongo --port 27018 --eval '
db = db.getSiblingDB("mymark_social_db");
db.platforms.drop();
db.accounts.drop();
db.posts.drop();

db.createCollection("platforms", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name"],
      properties: {
        name: { bsonType: "string", description: "Name of the platform" }
      }
    }
  }
});
db.createCollection("accounts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["platform_id", "handle"],
      properties: {
        platform_id: { bsonType: "objectId", description: "Reference to platforms _id" },
        handle: { bsonType: "string", description: "Account handle" }
      }
    }
  }
});
db.createCollection("posts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["account_id", "ts", "media_type", "media_path", "phash64", "face_embeds", "caption"],
      properties: {
        account_id: { bsonType: "objectId", description: "Reference to accounts _id" },
        ts: { bsonType: "date", description: "Timestamp of the post" },
        media_type: { bsonType: "string", description: "Media type" },
        media_path: { bsonType: "string", description: "Path to media file" },
        phash64: { bsonType: "string", description: "64-bit perceptual hash" },
        face_embeds: { bsonType: "array", description: "Array of face embedding binaries" },
        caption: { bsonType: "string", description: "Post caption" }
      }
    }
  }
});
'

echo "MongoDB collections created with schema validation."
