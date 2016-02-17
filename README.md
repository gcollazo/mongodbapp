# mongoDB.app

### The easiest way to get started with mongoDB on the Mac.
_Just download, drag to the applications folder, and double-click._

![mongoDB.app Screenshot](https://gcollazo.github.io/mongodbapp/assets/img/screenshot.png)

### [Download](http://gcollazo.github.io/mongodbapp)

---

### Version numbers

Version numbers of this project (mongoDB.app) try to communicate the included version of the included mongoDB binaries bundled with each release.

The version number also includes a build number which is used to indicate the current version of mongoDB.app and it's independent from the bundled mongoDB's version.

## Adding mongo binaries to your path
If you need to add the mongoDB binaries to your path you can do so by adding the following to your `~/.bash_profile`.

```bash
# Add mongoDB.app binaries to path
PATH="/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb:$PATH"
```
