#!/usr/bin/env bash

# Download latest mongodb for mac
curl -o /tmp/mongodb.tgz  https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-2.6.7.tgz

# Create dir
mkdir -p Vendor/mongodb

# Extract
tar xvzf /tmp/mongodb.tgz -C /tmp

# move files
mv /tmp/mongodb-osx-x86_64-2.6.7/* Vendor/mongodb

# cleanup
rm /tmp/mongodb.tgz
rm -r /tmp/mongodb-osx-x86_64-2.6.7

echo "Done!"
