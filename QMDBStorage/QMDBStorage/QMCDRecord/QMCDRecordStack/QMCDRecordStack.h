//
//  QMCDRecordStack.h
//  QMCDRecord
//
//  Created by Saul Mora on 9/14/13.
//  Copyright (c) 2013 QMCD Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface QMCDRecordStack : NSObject

@property (nonatomic, copy) NSString *stackName;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSPersistentStore *store;

@property (nonatomic, assign) BOOL loggingEnabled;
@property (nonatomic, assign) BOOL saveOnApplicationWillTerminate;
@property (nonatomic, assign) BOOL saveOnApplicationWillResignActive;

+ (instancetype) defaultStack;
+ (void) setDefaultStack:(QMCDRecordStack *)stack;

+ (instancetype) stack;

- (void) reset;

- (NSManagedObjectContext *) newConfinementContext;

- (void) setModelFromClass:(Class)modelClass;
- (void) setModelNamed:(NSString *)modelName;

@end
