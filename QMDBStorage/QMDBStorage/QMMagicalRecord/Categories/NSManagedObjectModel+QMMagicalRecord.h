//
//  NSManagedObjectModel+QMMagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMagicalRecord.h"


@interface NSManagedObjectModel (QMMagicalRecord)

+ (NSManagedObjectModel *) QM_defaultManagedObjectModel;

+ (void) QM_setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel;

+ (NSManagedObjectModel *) QM_mergedObjectModelFromMainBundle;
+ (NSManagedObjectModel *) QM_newManagedObjectModelNamed:(NSString *)modelFileName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *) QM_managedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *) QM_newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *) QM_newModelNamed:(NSString *) modelName inBundle:(NSBundle*) bundle NS_RETURNS_RETAINED;

@end
