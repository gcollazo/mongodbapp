#!/usr/bin/env bash

echo "--> Getting version numbers"

# =========================== LAST VERSION INFO ================================
PREV_VERSION=$(curl -s https://gcollazo.github.io/mongodbapp/ | grep -o '<p class="versions versions--main">v.*' | grep -o '[0-9]*\.[0-9]*\.[0-9]*-build\.[0-9]*')

PREV_MONGO=$(echo $PREV_VERSION | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
PREV_BUILD=$(echo $PREV_VERSION | grep -o '[0-9]*$')

echo "--> Previous mongodb version: $PREV_MONGO"


# =========================== NEW VERSION INFO =================================
# Get latest mongodb Production Relase version
VERSION=$(curl -s https://www.mongodb.org/downloads | grep -o 'Current Stable Release (.*)' | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo "--> Current mongodb version: $VERSION"


# =========================== COMPARE VERSIONS =================================
if [ "$PREV_MONGO" == "$VERSION" ]; then
  echo "--> No need to update :)"
  echo "==> Done!"
  exit 0
fi


# =========================== DOWNLOAD =========================================
# Create download url
DOWNLOAD_URL="http://downloads.mongodb.org/osx/mongodb-osx-ssl-x86_64-$VERSION.tgz"

# Download latest mongodb for mac
echo "--> Downloading: $DOWNLOAD_URL"
curl -o /tmp/mongodb.tgz $DOWNLOAD_URL

# Clean old mongodb dir
echo "--> Cleaning directory $(pwd)/Vendor/mongodb"
rm -rf $(pwd)/Vendor/mongodb

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

echo "--> Download completed!"


# =========================== BUILD ============================================
BUILD_VERSION="${VERSION}-build.$(date +%s)"

echo "--> Update Info.plist version ${BUILD_VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_VERSION}" MongoDB/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BUILD_VERSION}" MongoDB/Info.plist

echo "--> Clean build folder"
rm -rf build/

echo "--> Build with defaults"
xcodebuild

echo "--> Build completed!"


# =========================== RELEASE ==========================================
echo "--> Zip"
cd build/Release
zip -r -y ~/Desktop/MongoDB.zip MongoDB.app
cd ../../

# Get zip file size
FILE_SIZE=$(du ~/Desktop/MongoDB.zip | cut -f1)

echo "--> Create AppCast post"
rm -r ./_posts/release
mkdir -p ./_posts/release/

echo "---
version: $BUILD_VERSION
mongo_version: $VERSION
package_url: https://github.com/gcollazo/mongodbapp/releases/download/$BUILD_VERSION/MongoDB.zip
package_length: $FILE_SIZE
category: release
---

- Updates mongodb to $VERSION
" > ./_posts/release/$(date +"%Y-%m-%d")-${BUILD_VERSION}.md


# =========================== PUBLISH ==========================================
echo ""
echo "================== Next steps =================="
echo ""
echo "git commit -am $BUILD_VERSION"
echo "git tag $BUILD_VERSION"
echo "git push origin --tags"
echo ""
echo "Upload the zip file to GitHub"
echo "https://github.com/gcollazo/mongodbapp/releases/tag/$BUILD_VERSION"
echo ""
echo "git co gh-pages"
echo "git add ."
echo "git commit -am 'Release $BUILD_VERSION'"
echo "git push origin gh-pages"
echo ""
echo "==> Done!"
