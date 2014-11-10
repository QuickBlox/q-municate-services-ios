//
//  NSManagedObjectModel+QMMagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 QMMagical Panda Software, LLC All rights reserved.
//

//#import "NSManagedObjectModel+QMMagicalRecord.h"
#import "CoreData+QMMagicalRecord.h"


static NSManagedObjectModel *defaultManagedObjectModel_ = nil;

@implementation NSManagedObjectModel (QMMagicalRecord)

+ (NSManagedObjectModel *) QM_defaultManagedObjectModel
{
	if (defaultManagedObjectModel_ == nil && [QMMagicalRecord shouldAutoCreateManagedObjectModel])
	{
        [self QM_setDefaultManagedObjectModel:[self QM_mergedObjectModelFromMainBundle]];
	}
	return defaultManagedObjectModel_;
}

+ (void) QM_setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel
{
	defaultManagedObjectModel_ = newDefaultModel;
}

+ (NSManagedObjectModel *) QM_mergedObjectModelFromMainBundle;
{
    return [self mergedModelFromBundles:nil];
}

+ (NSManagedObjectModel *) QM_newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[modelName stringByDeletingPathExtension] 
                                                     ofType:[modelName pathExtension] 
                                                inDirectory:bundleName];
    NSURL *modelUrl = [NSURL fileURLWithPath:path];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
    
    return mom;
}

+ (NSManagedObjectModel *) QM_newModelNamed:(NSString *) modelName inBundle:(NSBundle*) bundle
{
    NSString *path = [bundle pathForResource:[modelName stringByDeletingPathExtension]
                                                     ofType:[modelName pathExtension]];
    NSURL *modelUrl = [NSURL fileURLWithPath:path];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
    
    return mom;
}

+ (NSManagedObjectModel *) QM_newManagedObjectModelNamed:(NSString *)modelFileName
{
	NSString *path = [[NSBundle mainBundle] pathForResource:[modelFileName stringByDeletingPathExtension] 
                                                     ofType:[modelFileName pathExtension]];
	NSURL *momURL = [NSURL fileURLWithPath:path];
	
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	return model;
}

+ (NSManagedObjectModel *) QM_managedObjectModelNamed:(NSString *)modelFileName
{
    NSManagedObjectModel *model = [self QM_newManagedObjectModelNamed:modelFileName];
	return model;
}

@end
