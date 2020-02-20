#!/bin/bash
set -e

echo "creating persistant directory..."
mkdir -p "$DATA_PATH"

echo "starting bitcoin core..."
exec bitcoind -disablewallet -datadir="$DATA_PATH"
