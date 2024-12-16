#!/usr/bin/sh

echo "creating $DATA_DIRECTORY..."
mkdir -p "$DATA_DIRECTORY"

echo "setting ownership..."
chown -R "$USER_ID":"$GROUP_ID" "$DATA_DIRECTORY"
echo "setting permissions..."
if [ "$GROUP_READABLE" == "1" ]; then
  echo "750..."
  chmod -R 750 "$DATA_DIRECTORY"
else
  echo "700..."
  chmod -R 700 "$DATA_DIRECTORY"
fi