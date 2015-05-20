#!/usr/bin/env bash

# Get latest Production Relase version number
echo "--> Getting Production Release version number"
VERSION=$(curl -s https://www.mongodb.org/downloads | grep -o 'Current Stable Release (.*)' | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo "--> Production Release: $VERSION"

# Create download url
DOWNLOAD_URL="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-$VERSION.tgz"

# Download latest mongodb for mac
echo "--> Downloading: $DOWNLOAD_URL"
curl -o /tmp/mongodb.tgz $DOWNLOAD_URL

# Create dir
echo "--> Creating directory $(pwd)/Vendor/mongodb"
mkdir -p $(pwd)/Vendor/mongodb

# Extract
echo "--> Unzipping..."
tar xvzf /tmp/mongodb.tgz -C /tmp

# move files
echo "--> Moving files to $(pwd)/Vendor/mongodb/"
mv /tmp/mongodb-osx-x86_64-*/* Vendor/mongodb

# cleanup
echo "--> Removing /tmp/mongodb.tgz"
rm /tmp/mongodb.tgz

echo "--> Removing /tmp/mongodb-osx-x86_64-*"
rm -r /tmp/mongodb-osx-x86_64-*

echo "--> Done!"
