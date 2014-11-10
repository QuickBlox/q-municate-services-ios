//
//  NSEntityDescription+QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 9/5/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "NSEntityDescription+QMMagicalDataImport.h"

@implementation NSEntityDescription (QMMagicalRecord_DataImport)

- (NSAttributeDescription *) QM_primaryAttributeToRelateBy;
{
    NSString *lookupKey = [[self userInfo] valueForKey:kQMMagicalRecordImportRelationshipLinkedByKey] ?: QM_primaryKeyNameFromString([self name]);

    return [self QM_attributeDescriptionForName:lookupKey];
}

- (NSManagedObject *) QM_createInstanceInContext:(NSManagedObjectContext *)context;
{
    Class relatedClass = NSClassFromString([self managedObjectClassName]);
    NSManagedObject *newInstance = [relatedClass QM_createEntityInContext:context];
   
    return newInstance;
}

- (NSAttributeDescription *) QM_attributeDescriptionForName:(NSString *)name;
{
    __block NSAttributeDescription *attributeDescription;

    NSDictionary *attributesByName = [self attributesByName];

    if ([attributesByName count] == 0) {
        return nil;
    }

    [attributesByName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:name]) {
            attributeDescription = obj;

            *stop = YES;
        }
    }];

    return attributeDescription;
}

@end
