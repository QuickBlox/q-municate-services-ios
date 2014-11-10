//
//  NSManagedObjectContext+QMMagicalThreading.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (QMMagicalThreading)

+ (NSManagedObjectContext *) QM_contextForCurrentThread __attribute((deprecated("This method will be removed in QMMagicalRecord 3.0")));
+ (void) QM_clearNonMainThreadContextsCache __attribute((deprecated("This method will be removed in QMMagicalRecord 3.0")));
+ (void) QM_resetContextForCurrentThread __attribute((deprecated("This method will be removed in QMMagicalRecord 3.0")));
+ (void) QM_clearContextForCurrentThread __attribute((deprecated("This method will be removed in QMMagicalRecord 3.0")));

@end
