//
//  NSPersistentStore+QMMagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

#import "QMMagicalRecord.h"
#import <CoreData/CoreData.h>

// option to autodelete store if it already exists

extern NSString * const kQMMagicalRecordDefaultStoreFileName;


@interface NSPersistentStore (QMMagicalRecord)

+ (NSURL *) QM_defaultLocalStoreUrl;

+ (NSPersistentStore *) QM_defaultPersistentStore;
+ (void) QM_setDefaultPersistentStore:(NSPersistentStore *) store;

+ (NSURL *) QM_urlForStoreName:(NSString *)storeFileName;
+ (NSURL *) QM_cloudURLForUbiqutiousContainer:(NSString *)bucketName;

@end


