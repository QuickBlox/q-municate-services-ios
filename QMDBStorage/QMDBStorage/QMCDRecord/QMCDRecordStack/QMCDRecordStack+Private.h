//
//  QMCDRecordStack_Private.h
//  QMCDRecord
//
//  Created by Saul Mora on 9/15/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import "QMCDRecordStack.h"

@interface QMCDRecordStack ()

- (NSPersistentStoreCoordinator *) createCoordinator;
- (NSPersistentStoreCoordinator *) createCoordinatorWithOptions:(NSDictionary *)options;

- (NSManagedObjectContext *) createConfinementContext;
- (void) loadStack;

@end
