#!/usr/bin/env bash

# =========================== CHECK FORCE FLAG =================================
if [ "$1" == "--force" ]; then
  FORCE=true
fi


# =========================== CURRENT VERSION INFO =============================
echo "--> Getting version numbers"

CURR_VERSION=$(curl -s https://gcollazo.github.io/mongodbapp/ | grep -o '<div class="current-version">v.*' | grep -o '[0-9]*\.[0-9]*\.[0-9]*-build\.[0-9]*')

CURR_MONGO=$(echo "$CURR_VERSION" | grep -o '^[0-9]*\.[0-9]*\.[0-9]*')
CURR_BUILD=$(echo "$CURR_VERSION" | grep -o '[0-9]*$')

echo " -- Current mongodb.app version: $CURR_MONGO"


# =========================== LATEST VERSION INFO ==============================
# Get latest mongodb Production Relase version
VERSION=$(curl -s https://www.mongodb.com/download-center/community | \
  grep -o '<option value="1" selected>.* (current release)</option>' | \
  grep -o '[0-9]*\.[0-9]*\.[0-9]*')
echo " -- Latest mongodb version: $VERSION"

# =========================== COMPARE VERSIONS =================================
if [ "$FORCE" != true ] && [ "$CURR_MONGO" == "$VERSION" ]; then
  echo " -- No need to update :)"
  echo "==> Done!"
  exit 0
fi


# =========================== DOWNLOAD =========================================
echo '--> Download'
DOWNLOAD_URL="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-$VERSION.tgz"

# Download latest mongodb for mac
echo " -- Downloading: $DOWNLOAD_URL"
curl -o /tmp/mongodb.tgz $DOWNLOAD_URL

# Clean old mongodb dir
echo " -- Cleaning directory $(pwd)/Vendor/mongodb"
rm -rf "$(pwd)/Vendor/mongodb"

# Create dir
echo " -- Creating directory $(pwd)/Vendor/mongodb"
mkdir -p "$(pwd)/Vendor/mongodb"

# Extract
echo " -- Unzipping..."
tar xvzf /tmp/mongodb.tgz -C /tmp

# move files
echo " -- Moving files to $(pwd)/Vendor/mongodb/"
mv /tmp/mongodb-macos-x86_64-*/* Vendor/mongodb

# cleanup
echo " -- Removing /tmp/mongodb.tgz"
rm /tmp/mongodb.tgz

echo " -- Removing /tmp/mongodb-macos-x86_64-*"
rm -r /tmp/mongodb-macos-x86_64-*

echo " -- Download completed!"


# =========================== BUILD ============================================
echo '--> Building'
# Use sequential build numbers
if [ "$FORCE" ]; then
  NEW_BUILD=$((CURR_BUILD + 1))
else
  NEW_BUILD=1
fi

RELEASE_VERSION="${VERSION}-build.${NEW_BUILD}"

echo " -- Update Info.plist version ${RELEASE_VERSION}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${RELEASE_VERSION}" MongoDB/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${RELEASE_VERSION}" MongoDB/Info.plist

echo " -- Clean build folder"
rm -rf build/

echo " -- Build with defaults"
xcodebuild

echo " -- Build completed!"


# =========================== RELEASE ==========================================
echo '--> Release'
echo " -- Zip"
cd build/Release || exit
zip -r -y ~/Desktop/MongoDB.zip MongoDB.app
cd ../../ || exit

# Get zip file size
FILE_SIZE=$(du ~/Desktop/MongoDB.zip | cut -f1)

echo " -- Create AppCast post"
rm -r ./_posts/release
mkdir -p ./_posts/release/

echo "---
version: $RELEASE_VERSION
mongo_version: $VERSION
package_url: https://github.com/gcollazo/mongodbapp/releases/download/$RELEASE_VERSION/MongoDB.zip
package_length: $FILE_SIZE
category: release
---

- Updates mongodb to $VERSION
" > "./_posts/release/$(date +"%Y-%m-%d")-${RELEASE_VERSION}.md"


# =========================== PUBLISH ==========================================
echo ""
echo "================== Next steps =================="
echo ""
echo "git commit -am $RELEASE_VERSION"
echo "git tag $RELEASE_VERSION"
echo "git push origin --tags"
echo ""
echo "Upload the zip file to GitHub"
echo "https://github.com/gcollazo/mongodbapp/releases/tag/$RELEASE_VERSION"
echo ""
echo "git co gh-pages"
echo "git add ."
echo "git commit -am 'Release $RELEASE_VERSION'"
echo "git push origin gh-pages"
echo ""
echo "==> Done!"
