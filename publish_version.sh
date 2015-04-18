echo "--> Clean build folder"
rm -rf build/

echo "--> Build with defaults"
xcodebuild

echo "--> Zip"
cd build/Release
zip -r -y ~/Desktop/MongoDB.zip MongoDB.app
cd ../../

# Get zip file size
FILE_SIZE=$(du ~/Desktop/MongoDB.zip | cut -f1)

# Get app version
VERSION=$(defaults read ~/Code/mongodbapp/MongoDB/Info.plist CFBundleShortVersionString)

# Get date
DATE_TIME=$(date +"%a, %d %b %G %H:%M:%S %z")

echo "--> Creting a git tag"
git tag $VERSION

echo "--> Echo Appcast item"
echo "============================="
echo "
<item>
  <title>{VERSION TITLE HERE}</title>
  <description>
    <![CDATA[
      <h2>{VERSION TITLE HERE}</h2>
      <ul>
        <li>{NEW FEAUTES OR CHANGES}</li>
      </ul>
    ]]>
  </description>
  <pubDate>$DATE_TIME</pubDate>
  <enclosure url=\"https://github.com/gcollazo/mongodbapp/releases/download/$VERSION/MongoDB.zip\" sparkle:version=\"$VERSION\" length=\"$FILE_SIZE\" type=\"application/octet-stream\"/>
  <sparkle:minimumSystemVersion>10.10</sparkle:minimumSystemVersion>
</item>
"
echo "============================="

echo "--> Done"
echo ""


echo "Next steps:"
echo ""
echo "git push origin --tags"
echo ""
echo "Upload the zip file to GitHub"
echo "https://github.com/gcollazo/mongodbapp/releases/tag/$VERSION"
echo ""
echo "Update Appcast file."
echo ""
echo ""
