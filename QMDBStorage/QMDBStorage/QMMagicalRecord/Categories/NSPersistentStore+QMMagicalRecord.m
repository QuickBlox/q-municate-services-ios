//
//  NSPersistentStore+QMMagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

//#import "NSPersistentStore+QMMagicalRecord.h"
#import "CoreData+QMMagicalRecord.h"

NSString * const kQMMagicalRecordDefaultStoreFileName = @"QMCoreDataStore.sqlite";

static NSPersistentStore *defaultPersistentStore_ = nil;


@implementation NSPersistentStore (QMMagicalRecord)

+ (NSPersistentStore *) QM_defaultPersistentStore
{
	return defaultPersistentStore_;
}

+ (void) QM_setDefaultPersistentStore:(NSPersistentStore *) store
{
	defaultPersistentStore_ = store;
}

+ (NSString *) QM_directory:(int) type
{    
    return [NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)QM_applicationDocumentsDirectory 
{
	return [self QM_directory:NSDocumentDirectory];
}

+ (NSString *)QM_applicationStorageDirectory
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    return [[self QM_directory:NSApplicationSupportDirectory] stringByAppendingPathComponent:applicationName];
}

+ (NSURL *) QM_urlForStoreName:(NSString *)storeFileName
{
	NSArray *paths = [NSArray arrayWithObjects:[self QM_applicationDocumentsDirectory], [self QM_applicationStorageDirectory], nil];
    NSFileManager *fm = [[NSFileManager alloc] init];
    
    for (NSString *path in paths) 
    {
        NSString *filepath = [path stringByAppendingPathComponent:storeFileName];
        if ([fm fileExistsAtPath:filepath])
        {
            return [NSURL fileURLWithPath:filepath];
        }
    }

    //set default url
    return [NSURL fileURLWithPath:[[self QM_applicationStorageDirectory] stringByAppendingPathComponent:storeFileName]];
}

+ (NSURL *) QM_cloudURLForUbiqutiousContainer:(NSString *)bucketName;
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *cloudURL = nil;
    if ([fileManager respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)])
    {
        cloudURL = [fileManager URLForUbiquityContainerIdentifier:bucketName];
    }

    return cloudURL;
}

+ (NSURL *) QM_defaultLocalStoreUrl
{
    return [self QM_urlForStoreName:kQMMagicalRecordDefaultStoreFileName];
}

@end
