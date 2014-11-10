//
//  QMMagicalRecord+Actions.h
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 QMMagical Panda Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+QMMagicalRecord.h"
#import "NSManagedObjectContext+QMMagicalSaves.h"

@interface QMMagicalRecord (Actions)

/* For all background saving operations. These calls will be sent to a different thread/queue.
 */
+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block;
+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(QMSaveCompletionHandler)completion;

/* For saving on the current thread as the caller, only with a seperate context. Useful when you're managing your own threads/queues and need a serial call to create or change data
 */
+ (void) saveWithBlockAndWait:(void(^)(NSManagedObjectContext *localContext))block;

@end

@interface QMMagicalRecord (ActionsDeprecated)

+ (void) saveUsingCurrentThreadContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(QMSaveCompletionHandler)completion QM_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
+ (void) saveUsingCurrentThreadContextWithBlockAndWait:(void (^)(NSManagedObjectContext *localContext))block QM_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block QM_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))completion QM_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
+ (void) saveInBackgroundUsingCurrentContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(void (^)(void))completion errorHandler:(void (^)(NSError *error))errorHandler QM_DEPRECATED_WILL_BE_REMOVED_IN("3.0");

@end
