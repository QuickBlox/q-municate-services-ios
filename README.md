# QMServices

Easy-to-use services for Quickblox SDK, for speeding up development of iOS chat applications.

# Features

# Requirements

- XCode 6+
- ARC
- Quickblox
- Mogenerator

# Dependencies

- Quickblox V2.0+
- Mogenerator

# Installation

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

> ** NOTE** Please be aware that if you've set Xcode's **Link Frameworks Automatically** to **No** then you may need to add the Quickblox.framework, CoreData.framework to your project on iOS, as UIKit does not include Core Data by default. On OS X, Cocoa includes Core Data.

Remember, that you have to link *QMServices* in **Target Dependencies** and in **Link Binary with Libraries**.

## mogenerator
generates ***Objective-C*** code for your ***Core Data*** custom classes
Unlike Xcode, ***mogenerator*** manages two classes per entity: one for machines, one for humans

The machine class can always be overwritten to match the data model, with humans’ work effortlessly preserved
##install via [homebrew](http://brew.sh):
$ brew install mogenerator

# Architecture

QMServices consists from <br>
 – **QMAuthService** <br>
 – **QMChatService** <br>
– **QMContactListService** <br>
They all inherited from **QMBaseService** <br>
To support CoreData caching you can use **QMContactListCache** and **QMChatCache**, they all inherited from **QMDBStorage** so you can write your own cache manager.  <br> <br>

# Getting started
To start using services you should create **QBServicesManager** <br>
Here is **QBServicesManager.h**:

```objective-c
@interface QBServicesManager : NSObject
@property (nonatomic, readonly) QMAuthService* authService; 
@property (nonatomic, readonly) QMChatService* chatService;
@property (nonatomic, readonly) UsersService* usersService;
@end
```

And extension in **QBServicesManager.m**:

```objective-c
@interface QBServicesManager () <QMServiceManagerProtocol, QMChatServiceCacheDataSource, QMContactListServiceCacheDataSource, QMChatServiceDelegate>

@property (nonatomic, strong) QMAuthService* authService;
@property (nonatomic, strong) QMChatService* chatService;
@property (nonatomic, strong) UsersService* usersService;
@property (nonatomic, strong) QMContactListService* contactListService;

@end
```

In ``init`` method, services and cache are initialised.

```objective-c
@implementation QBServicesManager

- (instancetype)init {
	self = [super init];
	if (self) {
		[QMChatCache setupDBWithStoreNamed:@"sample-cache"];
		[QMContactListCache setupDBWithStoreNamed:@"sample-cache-contacts"];
		_authService = [[QMAuthService alloc] initWithServiceManager:self];
		_chatService = [[QMChatService alloc] initWithServiceManager:self cacheDataSource:self];
		_contactListService = [[QMContactListService alloc] initWithServiceManager:self cacheDataSource:self];
	}
	return self;
}
```

* Cache setup (You could skip it if you don't need persistent storage).

	* Initiates Core Data database for dialog and messages:

	```objective-c
	[QMChatCache setupDBWithStoreNamed:@"sample-cache"];
	```

	* Initiates Core Data database for users from contact list.

	```objective-c
	[QMContactListCache setupDBWithStoreNamed:@"sample-cache-contacts"];
	```

* Services setup

	* Authentication service:

	
	```objective-c
	_authService = [[QMAuthService alloc] initWithServiceManager:self];
	```
	
	* Chat service (responsible for establishing chat connection and responding to chat events (message, presences and so on)):

	```objective-c
	_chatService = [[QMChatService alloc] initWithServiceManager:self cacheDataSource:self];
	```

	* Contact List service (responsible for managing users from XMPP roster):

	```objective-c
	_contactListService = [[QMContactListService alloc] initWithServiceManager:self cacheDataSource:self];
	```


In the next step 

# Quick tips

# Questions & Help

# Documentation

# About

# License
