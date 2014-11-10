//
//  NSDictionary+QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSObject+QMMagicalDataImport.h"
#import "NSEntityDescription+QMMagicalDataImport.h"
#import "NSManagedObject+QMMagicalDataImport.h"
#import "QMMagicalRecord.h"
#import "CoreData+QMMagicalRecord.h"
#import "QMMagicalRecordLogging.h"

NSUInteger const kQMMagicalRecordImportMaximumAttributeFailoverDepth = 10;


@implementation NSObject (QMMagicalRecord_DataImport)

- (NSString *) QM_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
{
    NSString *attributeName = [attributeInfo name];
    NSString *lookupKey = [[attributeInfo userInfo] valueForKey:kQMMagicalRecordImportAttributeKeyMapKey] ?: attributeName;
    
    id value = [self valueForKeyPath:lookupKey];
    
    for (NSUInteger i = 1; i < kQMMagicalRecordImportMaximumAttributeFailoverDepth && value == nil; i++)
    {
        attributeName = [NSString stringWithFormat:@"%@.%lu", kQMMagicalRecordImportAttributeKeyMapKey, (unsigned long)i];
        lookupKey = [[attributeInfo userInfo] valueForKey:attributeName];
        if (lookupKey == nil) 
        {
            return nil;
        }
        value = [self valueForKeyPath:lookupKey];
    }
    
    return value != nil ? lookupKey : nil;
}

- (id) QM_valueForAttribute:(NSAttributeDescription *)attributeInfo
{
    NSString *lookupKey = [self QM_lookupKeyForAttribute:attributeInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

- (NSString *) QM_lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
    if (destinationEntity == nil) 
    {
        QMMRLogError(@"Unable to find entity for type '%@'", [self valueForKey:kQMMagicalRecordImportRelationshipTypeKey]);
        return nil;
    }
    
    NSString               *primaryKeyName      = [relationshipInfo QM_primaryKey];
    NSAttributeDescription *primaryKeyAttribute = [destinationEntity QM_attributeDescriptionForName:primaryKeyName];
    NSString               *lookupKey           = [self QM_lookupKeyForAttribute:primaryKeyAttribute] ?: [primaryKeyAttribute name];

    return lookupKey;
}

- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSString *lookupKey = [self QM_lookupKeyForRelationship:relationshipInfo];
    return lookupKey ? [self valueForKeyPath:lookupKey] : nil;
}

@end
