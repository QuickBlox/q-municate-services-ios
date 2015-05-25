# Installing QMServices

**Adding QMServices to your project is simple**: Just choose whichever method you're most comfortable with and follow the instructions below.

## Using an Xcode subproject

Xcode sub-projects allow your project to use and build QMServices as an implicit dependency.

Add QMServices to your project as a Git submodule:
```
$ cd MyXcodeProjectFolder
$ git submodule add https://github.com/QuickBlox/q-municate-services-ios.git Vendor/QMServices
$ git commit -m "Add QMServices submodule"
```
Drag `Vendor/QMServices/QMServices ` into your existing Xcode project.

Navigate to your project's settings, then select the target you wish to add QMServices to.

Navigate to **Build Settings**, then search for **Header Search Paths** and double-click it to edit

Add a new item using **+**: `"$(SRCROOT)/Vendor/QMServices/QMServices"` and ensure that it is set to *recursive*

Navigate to **Build Settings**, then search for **Framework Search Paths** and double-click it to edit

> ** NOTE**: By default, the Quickblox framework is set to `~/Documents/Quickblox`.
> To change the path to Quickblox.framework, you need to open Quickblox.xcconfig file and replace `~/Documents/Quickblox` with your path to the Quickblox.framework.

Add a new item using **+**: `~/Documents/Quickblox` and ensure that it is set to *recursive*

> ** NOTE** Please be aware that if you've set Xcode's **Link Frameworks Automatically** to **No** then you may need to add the Quickblox.framework CoreData.framework to your project on iOS, as UIKit does not include Core Data by default. On OS X, Cocoa includes Core Data.

# mogenerator
generates ***Objective-C*** code for your ***Core Data*** custom classes
Unlike Xcode, ***mogenerator*** manages two classes per entity: one for machines, one for humans

The machine class can always be overwritten to match the data model, with humans’ work effortlessly preserved
##install via [homebrew](http://brew.sh):
$ brew install mogenerator
