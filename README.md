# MongoDB.app

### The easiest way to get started with MongoDB on the Mac.
_Just download, drag to the applications folder, and double-click._

![MongoDB.app Screenshot](screenshot.png)

![](https://img.shields.io/github/release/gcollazo/mongodbapp.svg)

<span style="font-size:24px">[Download](https://github.com/gcollazo/mongodbapp/releases)</span>

### Version numbers

Version numbers of this project (MongoDB.app) try to communicate the included version of the included MongoDB binaries bundled with each release.

The version number also includes a build number which is used to indicate the current version of MongoDB.app and it's independent from the bundled MongoDB's version. At the moment we use a unix timestamp for build versions in order to easily automate new releases.

For example version `v3.2.0.buid.1449793677` of MongoDB.app will include MongoDB version `3.2.0` and indicates that the current build of MongoDB.app is build `1449793677`.

## Adding mongo binaries to your path
If you need to add the MongoDB binaries to your path you can do so by adding the following to your `~/.bash_profile`.

```bash
# Add MongoDB.app binaries to path
PATH="/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb:$PATH"
```
