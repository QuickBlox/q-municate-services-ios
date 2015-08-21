**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [QMServices](#)
- [Features](#)
- [Requirements](#)
- [Dependencies](#)
- [Installation](#)
	- [Using an Xcode subproject](#)
		- [Bundle generation (you can skip this step if you do not use dialogs, messages and users memory and disc storage)](#)
	- [Cocoapods](#)
- [Architecture](#)
- [Getting started](#)
	- [Service Manager](#)
	- [Authentication](#)
		- [Login](#)
		- [Logout](#)
	- [Fetching chat dialogs](#)
	- [Fetching chat messages](#)
	- [Sending message](#)
	- [Fetching users](#)
	- [Subclass of QMServicesManager example](#)
- [Documentation](#)
- [License](#)

# QMServices

Easy-to-use services for Quickblox SDK, for speeding up development of iOS chat applications.

# Features

* Inbox persistent storage for messages, dialogs and users
* Inbox memory storage for messages, dialogs and users
* Authentication service for logging to Quickblox REST and XMPP

# Requirements

- Xcode 6+
- ARC
- Quickblox SDK 2.0+

# Dependencies

- Quickblox SDK 2.0+

# Installation

There are several ways to add **QMServices** to your project. They are described below:

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

### Bundle generation (you can skip this step if you do not use dialogs, messages and users memory and disc storage)

Bundle allows to pass .xcdatamodel file together with static library so it is required for **QMChatCache** and **QMContactListCache** projects.

To generate bundle for contact list you need to open **QMServices** project, navigate to Cache folder and select **QMContactListCache.xcodeproj**. Open project folder - you will see red **QMContactListCacheModel.bundle**. To create it select scheme **QMContactListCacheModel** and run it. After successful build **QMContactListCacheModel.bundle** color will change to black and you will be able to copy it to the project that uses **QMServices**. Include this bundle in your project.

To generate bundle for dialogs and messages you need to open **QMServices** project, navigate to Cache folder and select **QMChatCache.xcodeproj**. Open project folder - you will see red **QMChatCacheModel.bundle**. To create it select scheme **QMChatCacheModel** and run it. After successful build **QMChatCacheModel.bundle`** color will change to black and you will be able to copy it to the project that uses **QMServices**. Include this bundle in your project.

## Cocoapods

You can install **QMServices** using Cocoapods just by adding following line in your Podfile:

pod 'QMServices', '~> 0.1'

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

To start using services you could either use existing **QMServicesManager** class or create a subclass from it.
Detailed explanation of the **QMServicesManager** class is below.

**QMServicesManager** has 2 functions - user login(login to REST API, chat)/logout(Logging out from chat, REST API, clearing persistent and memory cache) and establishing connection between **QMChatCache** and **QMChatService** to enable storing dialogs and messages data on disc.

Here is **QMServicesManager.h**:

```objective-c
@interface QMServicesManager : NSObject <QMServiceManagerProtocol, QMChatServiceCacheDataSource, QMChatServiceDelegate, QMChatConnectionDelegate>

+ (instancetype)instance;

- (void)logInWithUser:(QBUUser *)user completion:(void (^)(BOOL success, NSString *errorMessage))completion;
- (void)logoutWithCompletion:(dispatch_block_t)completion;

@property (nonatomic, readonly) QMAuthService* authService;
@property (nonatomic, readonly) QMChatService* chatService;

@end
```

And extension in **QMServicesManager.m**:

```objective-c
@interface QMServicesManager ()

@property (nonatomic, strong) QMAuthService* authService;
@property (nonatomic, strong) QMChatService* chatService;

@property (nonatomic, strong) dispatch_group_t logoutGroup;

@end
```

In ``init`` method, services and cache are initialised.

```objective-c
- (instancetype)init {
	self = [super init];
	if (self) {
		[QMChatCache setupDBWithStoreNamed:@"sample-cache"];
        	[QMChatCache instance].messagesLimitPerDialog = 10;

		_authService = [[QMAuthService alloc] initWithServiceManager:self];
		_chatService = [[QMChatService alloc] initWithServiceManager:self cacheDataSource:self];
        	[_chatService addDelegate:self];
        	_logoutGroup = dispatch_group_create();
	}
	return self;
}
```

* Cache setup (You could skip it if you don't need persistent storage).

	* Initiates Core Data database for dialog and messages:

	```objective-c
	[QMChatCache setupDBWithStoreNamed:@"sample-cache"];
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
	[QMChatCache.instance dialogsSortedBy:CDDialogAttributes.lastMessageDate ascending:YES completion:^(NSArray *dialogs) {
		block(dialogs);
	}];
}

- (void)cachedMessagesWithDialogID:(NSString *)dialogID block:(QMCacheCollection)block {
	[QMChatCache.instance messagesWithDialogId:dialogID sortedBy:CDMessageAttributes.messageID ascending:YES completion:^(NSArray *array) {
		block(array);
	}];
}
```

## Authentication

We encourage to use automatic session creation, to simplify communication with backend:

```objective-c
[QBConnection setAutoCreateSessionEnabled:YES];
```

### Login

This method logins user to Quickblox REST API backend and to the Quickblox Chat backend. Also it automatically tries to join to the group dialog - to immediately receive incomming messages.

```objective-c
- (void)logInWithUser:(QBUUser *)user
		   completion:(void (^)(BOOL success, NSString *errorMessage))completion
{
	[self.authService logInWithUser:user completion:^(QBResponse *response, QBUUser *userProfile) {
		if (response.error != nil) {
			if (completion != nil) {
				completion(NO, response.error.error.localizedDescription);
			}
			return;
		}
		
        	__weak typeof(self) weakSelf = self;
		[self.chatService logIn:^(NSError *error) {
            		__typeof(self) strongSelf = weakSelf;
			if (completion != nil) {
				completion(error == nil, error.localizedDescription);
			}
            		
			NSArray* dialogs = [strongSelf.chatService.dialogsMemoryStorage unsortedDialogs];
            		for (QBChatDialog* dialog in dialogs) {
                		if (dialog.type != QBChatDialogTypePrivate) {
                			[strongSelf.chatService joinToGroupDialog:dialog failed:^(NSError *error) {
						if (error != nil) {
							NSLog(@"Join error: %@", error.localizedDescription);
						}
                    			}];
                		}
            		}
		}];
	}];
}

```

Example of usage:

```objective-c
    // Logging in to Quickblox REST API and chat.
    [ServicesManager.instance logInWithUser:selectedUser completion:^(BOOL success, NSString *errorMessage) {
        if (success) {
        	// Handle success login
        } else {
            	// Handle error with error message
        }
    }];
```

### Logout

```objective-c
- (void)logoutWithCompletion:(void(^)())completion
{
    if ([QBSession currentSession].currentUser != nil) {
        __weak typeof(self)weakSelf = self;    
        
        dispatch_group_enter(self.logoutGroup);
        [self.authService logOut:^(QBResponse *response) {
            __typeof(self) strongSelf = weakSelf;
            [strongSelf.chatService logoutChat];
            [strongSelf.chatService free];
            dispatch_group_leave(strongSelf.logoutGroup);
        }];
        
        dispatch_group_enter(self.logoutGroup);
        [[QMChatCache instance] deleteAllDialogs:^{
            __typeof(self) strongSelf = weakSelf;
            dispatch_group_leave(strongSelf.logoutGroup);
        }];
        
        dispatch_group_enter(self.logoutGroup);
        [[QMChatCache instance] deleteAllMessages:^{
            __typeof(self) strongSelf = weakSelf;
            dispatch_group_leave(strongSelf.logoutGroup);
        }];
        
        dispatch_group_notify(self.logoutGroup, dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    } else {
        if (completion) {
            completion();
        }
    }
}
```

Example of usage:

```objective-c
    [[QMServicesManager instance] logoutWithCompletion:^{
        // Handle logout
    }];
```

## Fetching chat dialogs

Load all dialogs from REST API:

Extended request parameters could be taken from http://quickblox.com/developers/SimpleSample-chat_users-ios#Filters.

```objective-c

[QBServicesManager.instance.chatService allDialogsWithPageLimit:100 extendedRequest:nil iterationBlock:^(QBResponse *response, NSArray *dialogObjects, NSSet *dialogsUsersIDs, BOOL *stop) {
	// reload UI, this block is called when page is loaded
} completion:^(QBResponse *response) {
	// loading finished, all dialogs fetched
}];
```

These dialogs are automatically stored in **QMDialogsMemoryStorage** class.

## Fetching chat messages

Fetching messages from REST API history:

```objective-c
[QBServicesManager instance].chatService messagesWithChatDialogID:@"53fdc87fe4b0f91d92fbb27e" completion:^(QBResponse *response, NSArray *messages) {
	// update UI, handle messages
}];
```

These message are automatically stored in **QMMessagesMemoryStorage** class.

## Sending message

Send message to dialog:

```objective-c

QBChatMessage *message = [QBChatMessage message];
message.text = @"Awesome text";
message.senderID = 2308497;

[[QBServicesManager instance].chatService sendMessage:message toDialogId:@"53fdc87fe4b0f91d92fbb27e" save:YES completion:nil];
```

Message is automatically added to **QMMessagesMemoryStorage** class.

## Fetching users


```objective-c
[QBServicesManager.instance.contactListService retrieveUsersWithIDs:@[@(2308497)] completion:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
	// handle users
}];
```

Users are automatically stored in **QMUsersMemoryStorage** class.

## Subclass of QMServicesManager example

This example adds additional functionality - storing of users in contact list cache, error handling, storing currently opened dialog identifier.

Header file:

```objective-c
@interface ServicesManager : QMServicesManager <QMContactListServiceCacheDataSource>

// Replaces with any users service you are already using or going to use
@property (nonatomic, readonly) UsersService* usersService;

@property (nonatomic, strong) NSString* currentDialogID;

@end

```

Implementation file:

```objective-c
@interface ServicesManager ()

@property (nonatomic, strong) QMContactListService* contactListService;

@end

@implementation ServicesManager

- (instancetype)init {
	self = [super init];
    
	if (self) {
        [QMContactListCache setupDBWithStoreNamed:kContactListCacheNameKey];
		_contactListService = [[QMContactListService alloc] initWithServiceManager:self cacheDataSource:self];
		// Replace with any users service you are already using or going to use
		_usersService = [[UsersService alloc] initWithContactListService:_contactListService];
	}
    
	return self;
}

- (void)showNotificationForMessage:(QBChatMessage *)message inDialogID:(NSString *)dialogID
{
    if ([self.currentDialogID isEqualToString:dialogID]) return;
    
    if (message.senderID == self.currentUser.ID) return;
    
    NSString* dialogName = @"New message";
    
    QBChatDialog* dialog = [self.chatService.dialogsMemoryStorage chatDialogWithID:dialogID];
    
    if (dialog.type != QBChatDialogTypePrivate) {
        dialogName = dialog.name;
    } else {
        QBUUser* user = [[StorageManager instance] userByID:dialog.recipientID];
        if (user != nil) {
            dialogName = user.login;
        }
    }
    
    // Display notification UI
}

- (void)handleErrorResponse:(QBResponse *)response {
    
    [super handleErrorResponse:response];
    
    if (![self isAutorized]) return;
	NSString *errorMessage = [[response.error description] stringByReplacingOccurrencesOfString:@"(" withString:@""];
	errorMessage = [errorMessage stringByReplacingOccurrencesOfString:@")" withString:@""];
	
	if( response.status == 502 ) { // bad gateway, server error
		errorMessage = @"Bad Gateway, please try again";
	}
	else if( response.status == 0 ) { // bad gateway, server error
		errorMessage = @"Connection network error, please try again";
	}
    
    // Display notification UI
}

#pragma mark QMChatServiceCache delegate

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    [super chatService:chatService didAddMessageToMemoryStorage:message forDialogID:dialogID];
    
    [self showNotificationForMessage:message inDialogID:dialogID];
}

#pragma mark QMContactListServiceCacheDelegate delegate

- (void)cachedUsers:(QMCacheCollection)block {
	[QMContactListCache.instance usersSortedBy:@"id" ascending:YES completion:block];
}

- (void)cachedContactListItems:(QMCacheCollection)block {
	[QMContactListCache.instance contactListItems:block];
}

@end
```

# Documentation

Inline code documentation.

# License

See [LICENSE.txt](LICENSE.txt)
