#!/bin/bash
set -e

echo "building PhantomJS..."
git clone git://github.com/ariya/phantomjs.git
cd phantomjs
git checkout 2.0
./build.sh --confirm
