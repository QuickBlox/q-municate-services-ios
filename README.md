# QMServices

Easy-to-use services for Quickblox SDK, for speeding up development of iOS chat applications.

# Features

* Inbox persistent storage for messages, dialogs and users
* Inbox memory storage for messages, dialogs and users
* Authentication service for logging to Quickblox REST and XMPP

# Requirements

- Xcode 6+
- ARC
- Quickblox

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

QMServices contains:

* **QMAuthService**
* **QMChatService**
* **QMContactListService**


They all inherited from **QMBaseService**.
To support CoreData caching you can use **QMContactListCache** and **QMChatCache**, which are inherited from **QMDBStorage**. Of course you could use your own database storage - just need to implement **QMChatServiceDelegate**.

# Getting started
Add **#import \<QMServices.h\>** to your apps *.pch* file.

## Service Manager

To start using services you should create **QBServicesManager** class.

Here is **QBServicesManager.h**:

```objective-c
@interface QBServicesManager : NSObject
@property (nonatomic, readonly) QMAuthService* authService; 
@property (nonatomic, readonly) QMChatService* chatService;
@end
```

And extension in **QBServicesManager.m**:

```objective-c
@interface QBServicesManager () <QMServiceManagerProtocol, QMChatServiceCacheDataSource, QMContactListServiceCacheDataSource, QMChatServiceDelegate>

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
	
Also you have to implement **QMServiceManagerProtocol** methods:

```objective-c
- (void)handleErrorResponse:(QBResponse *)response {
	// handle error response from services here
}

- (BOOL)isAutorized {
	return self.authService.isAuthorized;
}

- (QBUUser *)currentUser {
	return [QBSession currentSession].currentUser;
}
```

To implement chat messages and dialogs caching you should implement following methods from **QMChatServiceDelegate** protocol:

```objective-c
- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog {
	[QMChatCache.instance insertOrUpdateDialog:chatDialog completion:nil];
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogsToMemoryStorage:(NSArray *)chatDialogs {
	[QMChatCache.instance insertOrUpdateDialogs:chatDialogs completion:nil];
}

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
	[QMChatCache.instance insertOrUpdateMessage:message withDialogId:dialogID completion:nil];
}

- (void)chatService:(QMChatService *)chatService didAddMessagesToMemoryStorage:(NSArray *)messages forDialogID:(NSString *)dialogID {
	[QMChatCache.instance insertOrUpdateMessages:messages withDialogId:dialogID completion:nil];
}

- (void)chatService:(QMChatService *)chatService didDeleteChatDialogWithIDFromMemoryStorage:(NSString *)chatDialogID {
    [QMChatCache.instance deleteDialogWithID:chatDialogID completion:nil];
}

- (void)chatService:(QMChatService *)chatService  didReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)dialog {
	[QMChatCache.instance insertOrUpdateMessage:message withDialogId:dialog.ID completion:nil];
	[QMChatCache.instance insertOrUpdateDialog:dialog completion:nil];
}

- (void)chatService:(QMChatService *)chatService didUpdateChatDialogInMemoryStorage:(QBChatDialog *)chatDialog {
    [[QMChatCache instance] insertOrUpdateDialog:chatDialog completion:nil];
}
```

Also for prefetching initial dialogs and messages you have to implement **QMChatServiceCacheDataSource** protocol:

```objective-c
- (void)cachedDialogs:(QMCacheCollection)block {
	[QMChatCache.instance dialogsSortedBy:@"lastMessageDate" ascending:YES completion:^(NSArray *dialogs) {
		block(dialogs);
	}];
}

- (void)cachedMessagesWithDialogID:(NSString *)dialogID block:(QMCacheCollection)block {
	[QMChatCache.instance messagesWithDialogId:dialogID sortedBy:CDMessageAttributes.messageID ascending:YES completion:^(NSArray *array) {
		block(array);
	}];
}
```

And for contact list service cache (**QMContactListServiceCacheDataSource**):

```objective-c
- (void)cachedUsers:(QMCacheCollection)block {
	[QMContactListCache.instance usersSortedBy:@"id" ascending:YES completion:^(NSArray *users) {
		block(users);
	}];
}

- (void)cachedContactListItems:(QMCacheCollection)block {
	[QMContactListCache.instance contactListItems:block];
}
```

## Authentication

We encourage to use automatic session creation, to simplify communication with backend:

```objective-c
[QBConnection setAutoCreateSessionEnabled:YES];
```

### Login

Usually you will implement following method in **QBServiceManager** class:

```objective-c
- (void)logInWithUser:(QBUUser *)user
		   completion:(void (^)(BOOL success, NSString *errorMessage))completion
{
        __weak typeof(self) weakSelf = self;
	[self.authService logInWithUser:user completion:^(QBResponse *response, QBUUser *userProfile) {
		if (response.error != nil) {
			if (completion != nil) {
				completion(NO, response.error.error.localizedDescription);
			}
			return;
		}		
		
		[self.chatService logIn:^(NSError *error) {
			if (completion != nil) {
				completion(error == nil, error.localizedDescription);
			}
 		}];
	}];
}
```

### Logout

```objective-c
- (void)logoutWithCompletion:(void(^)())completion
{
	if ([QBSession currentSession].currentUser != nil) {
		__weak typeof(self)weakSelf = self;           
		[self.authService logOut:^(QBResponse *response) {
			__typeof(self) strongSelf = weakSelf;
			[strongSelf.chatService logoutChat];
			if (completion) {
				completion();
			}
		}];        
   } else {
        if (completion) {
            completion();
        }
    }
}
```

## Fetching chat dialogs

Load all dialogs from REST API:

```objective-c
[QBServicesManager.instance.chatService allDialogsWithPageLimit:<your_page_limit> extendedRequest:nil iterationBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop) {
	// reload UI, this block is called when page is loaded
} completion:^(QBResponse *response) {
	// loading finished, all dialogs fetched
}];
```

These dialogs are automatically stored in **QMDialogsMemoryStorage** class.

## Fetching chat messages

Fetching messages from REST history:

```objective-c
[QBServicesManager instance].chatService messagesWithChatDialogID:<your_dialog_id> completion:^(QBResponse *response, NSArray *messages) {
	// update UI, handle messages
}];
```

These message are automatically stored in **QMMessagesMemoryStorage** class.

## Sending message

Send message to dialog:

```objective-c
[[QBServicesManager instance].chatService sendMessage:<your_message> toDialogId:<your_dialog_id> save:YES completion:nil];
```

Message is automatically added to **QMMessagesMemoryStorage** class.

## Fetching users


```objective-c
[QBServicesManager.instance.contactListService retrieveUsersWithIDs:<array_of_user_ids> completion:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
	// handle users
}];
```

Users are automatically stored in **QMUsersMemoryStorage** class.

# Documentation

Inline code documentation.

# License

See [LICENSE.txt](LICENSE.txt)
