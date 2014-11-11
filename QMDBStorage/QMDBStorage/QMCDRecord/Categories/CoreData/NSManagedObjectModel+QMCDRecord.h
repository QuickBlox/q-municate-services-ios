//
//  NSManagedObjectModel+QMCDRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMCD Panda Software, LLC All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (QMCDRecord)

+ (NSManagedObjectModel *)QM_managedObjectModelAtURL:(NSURL *)url;
+ (NSManagedObjectModel *)QM_mergedObjectModelFromMainBundle;
+ (NSManagedObjectModel *)QM_managedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *)QM_newModelNamed:(NSString *)modelName inBundleNamed:(NSString *)bundleName NS_RETURNS_RETAINED;

@end
