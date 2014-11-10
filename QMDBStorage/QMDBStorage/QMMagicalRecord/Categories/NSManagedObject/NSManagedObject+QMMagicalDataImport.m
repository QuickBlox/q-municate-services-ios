//
//  NSManagedObject+JSONHelpers.m
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "CoreData+QMMagicalRecord.h"
#import "NSObject+QMMagicalDataImport.h"
#import "QMMagicalRecordLogging.h"
#import <objc/runtime.h>

NSString * const kQMMagicalRecordImportCustomDateFormatKey            = @"dateFormat";
NSString * const kQMMagicalRecordImportDefaultDateFormatString        = @"yyyy-MM-dd'T'HH:mm:ssz";
NSString * const kQMMagicalRecordImportUnixTimeString                 = @"UnixTime";

NSString * const kQMMagicalRecordImportAttributeKeyMapKey             = @"mappedKeyName";
NSString * const kQMMagicalRecordImportAttributeValueClassNameKey     = @"attributeValueClassName";

NSString * const kQMMagicalRecordImportRelationshipMapKey             = @"mappedKeyName";
NSString * const kQMMagicalRecordImportRelationshipLinkedByKey        = @"relatedByAttribute";
NSString * const kQMMagicalRecordImportRelationshipTypeKey            = @"type";  //this needs to be revisited

NSString * const kQMMagicalRecordImportAttributeUseDefaultValueWhenNotPresent = @"useDefaultValueWhenNotPresent";

@implementation NSManagedObject (QMMagicalRecord_DataImport)

- (BOOL) QM_importValue:(id)value forKey:(NSString *)key
{
    NSString *selectorString = [NSString stringWithFormat:@"import%@:", [key QM_capitalizedFirstCharacterString]];
    SEL selector = NSSelectorFromString(selectorString);

    if ([self respondsToSelector:selector])
    {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        [invocation setTarget:self];
        [invocation setSelector:selector];
        [invocation setArgument:&value atIndex:2];
        [invocation invoke];

        BOOL returnValue = YES;
        [invocation getReturnValue:&returnValue];
        return returnValue;
    }

    return NO;
}

- (void) QM_setAttributes:(NSDictionary *)attributes forKeysWithObject:(id)objectData
{    
    for (NSString *attributeName in attributes) 
    {
        NSAttributeDescription *attributeInfo = [attributes valueForKey:attributeName];
        NSString *lookupKeyPath = [objectData QM_lookupKeyForAttribute:attributeInfo];
        
        if (lookupKeyPath) 
        {
            id value = [attributeInfo QM_valueForKeyPath:lookupKeyPath fromObjectData:objectData];
            if (![self QM_importValue:value forKey:attributeName])
            {
                [self setValue:value forKey:attributeName];
            }
        } 
        else 
        {
            if ([[[attributeInfo userInfo] objectForKey:kQMMagicalRecordImportAttributeUseDefaultValueWhenNotPresent] boolValue]) 
            {
                id value = [attributeInfo defaultValue];
                if (![self QM_importValue:value forKey:attributeName])
                {
                    [self setValue:value forKey:attributeName];
                }
            }
        }
    }
}

- (NSManagedObject *) QM_findObjectForRelationship:(NSRelationshipDescription *)relationshipInfo withData:(id)singleRelatedObjectData
{
    NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
    NSManagedObject *objectForRelationship = nil;

    id relatedValue;

    // if its a primitive class, than handle singleRelatedObjectData as the key for relationship
    if ([singleRelatedObjectData isKindOfClass:[NSString class]] ||
        [singleRelatedObjectData isKindOfClass:[NSNumber class]])
    {
        relatedValue = singleRelatedObjectData;
    }
    else if ([singleRelatedObjectData isKindOfClass:[NSDictionary class]])
	{
		relatedValue = [singleRelatedObjectData QM_relatedValueForRelationship:relationshipInfo];
	}
	else
    {
        relatedValue = singleRelatedObjectData;
    }

    if (relatedValue)
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        Class managedObjectClass = NSClassFromString([destinationEntity managedObjectClassName]);
        NSString *primaryKey = [relationshipInfo QM_primaryKey];
        objectForRelationship = [managedObjectClass QM_findFirstByAttribute:primaryKey
																  withValue:relatedValue
																  inContext:context];
    }
	
    return objectForRelationship;
}

- (void) QM_addObject:(NSManagedObject *)relatedObject forRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSAssert2(relatedObject != nil, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), [relationshipInfo name]);    
    NSAssert2([[relatedObject entity] isKindOfEntity:[relationshipInfo destinationEntity]], @"related object entity %@ not same as destination entity %@", [relatedObject entity], [relationshipInfo destinationEntity]);

    //add related object to set
    NSString *addRelationMessageFormat = @"set%@:";
    id relationshipSource = self;
    if ([relationshipInfo isToMany]) 
    {
        addRelationMessageFormat = @"add%@Object:";
        if ([relationshipInfo respondsToSelector:@selector(isOrdered)] && [relationshipInfo isOrdered])
        {
            //Need to get the ordered set
            NSString *selectorName = [[relationshipInfo name] stringByAppendingString:@"Set"];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            relationshipSource = [self performSelector:NSSelectorFromString(selectorName)];
#pragma clang diagnostic pop
            addRelationMessageFormat = @"addObject:";
        }
    }

    NSString *addRelatedObjectToSetMessage = [NSString stringWithFormat:addRelationMessageFormat, QM_attributeNameFromString([relationshipInfo name])];
 
    SEL selector = NSSelectorFromString(addRelatedObjectToSetMessage);

    @try
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [relationshipSource performSelector:selector withObject:relatedObject];
#pragma clang diagnostic pop
    }
    @catch (NSException *exception)
    {
        QMMRLogError(@"Adding object for relationship failed: %@\n", relationshipInfo);
        QMMRLogError(@"relatedObject.entity %@", [relatedObject entity]);
        QMMRLogError(@"relationshipInfo.destinationEntity %@", [relationshipInfo destinationEntity]);
        QMMRLogError(@"Add Relationship Selector: %@", addRelatedObjectToSetMessage);   
        QMMRLogError(@"perform selector error: %@", exception);
    }
}

- (void) QM_setRelationships:(NSDictionary *)relationships forKeysWithObject:(id)relationshipData withBlock:(void(^)(NSRelationshipDescription *,id))setRelationshipBlock
{
    for (NSString *relationshipName in relationships) 
    {
        if ([self QM_importValue:relationshipData forKey:relationshipName]) 
        {
            continue;
        }
        
        NSRelationshipDescription *relationshipInfo = [relationships valueForKey:relationshipName];
        
        NSString *lookupKey = [[relationshipInfo userInfo] valueForKey:kQMMagicalRecordImportRelationshipMapKey] ?: relationshipName;

        id relatedObjectData;

        @try
        {
            relatedObjectData = [relationshipData valueForKeyPath:lookupKey];
        }
        @catch (NSException *exception)
        {
            QMMRLogWarn(@"Looking up a key for relationship failed while importing: %@\n", relationshipInfo);
            QMMRLogWarn(@"lookupKey: %@", lookupKey);
            QMMRLogWarn(@"relationshipInfo.destinationEntity %@", [relationshipInfo destinationEntity]);
            QMMRLogWarn(@"relationshipData: %@", relationshipData);
            QMMRLogWarn(@"Exception:\n%@: %@", [exception name], [exception reason]);
        }
        @finally
        {
            if (relatedObjectData == nil || [relatedObjectData isEqual:[NSNull null]])
            {
                continue;
            }
        }
        
        SEL shouldImportSelector = NSSelectorFromString([NSString stringWithFormat:@"shouldImport%@:", [relationshipName QM_capitalizedFirstCharacterString]]);
        BOOL implementsShouldImport = (BOOL)[self respondsToSelector:shouldImportSelector];
        void (^establishRelationship)(NSRelationshipDescription *, id) = ^(NSRelationshipDescription *blockInfo, id blockData)
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if (!(implementsShouldImport && !(BOOL)[self performSelector:shouldImportSelector withObject:relatedObjectData]))
            {
                setRelationshipBlock(blockInfo, blockData);
            }
#pragma clang diagnostic pop
        };
        
        if ([relationshipInfo isToMany] && [relatedObjectData isKindOfClass:[NSArray class]])
        {
            for (id singleRelatedObjectData in relatedObjectData) 
            {
                establishRelationship(relationshipInfo, singleRelatedObjectData);
            }
        }
        else
        {
            establishRelationship(relationshipInfo, relatedObjectData);
        }
    }
}

- (BOOL) QM_preImport:(id)objectData;
{
    if ([self respondsToSelector:@selector(shouldImport:)])
    {
        BOOL shouldImport = (BOOL)[self shouldImport:objectData];
        if (!shouldImport) 
        {
            return NO;
        }
    }   

    if ([self respondsToSelector:@selector(willImport:)])
    {
        [self willImport:objectData];
    }

    return YES;
}

- (BOOL) QM_postImport:(id)objectData;
{
    if ([self respondsToSelector:@selector(didImport:)])
    {
        [self performSelector:@selector(didImport:) withObject:objectData];
    }

    return YES;
}

- (BOOL) QM_performDataImportFromObject:(id)objectData relationshipBlock:(void(^)(NSRelationshipDescription*, id))relationshipBlock;
{
    BOOL didStartimporting = [self QM_preImport:objectData];
    if (!didStartimporting) return NO;
    
    NSDictionary *attributes = [[self entity] attributesByName];
    [self QM_setAttributes:attributes forKeysWithObject:objectData];
    
    NSDictionary *relationships = [[self entity] relationshipsByName];
    [self QM_setRelationships:relationships forKeysWithObject:objectData withBlock:relationshipBlock];
    
    return [self QM_postImport:objectData];  
}

- (BOOL) QM_importValuesForKeysWithObject:(id)objectData
{
	__weak typeof(self) weakself = self;
    return [self QM_performDataImportFromObject:objectData
                              relationshipBlock:^(NSRelationshipDescription *relationshipInfo, id localObjectData) {
        
        NSManagedObject *relatedObject = [weakself QM_findObjectForRelationship:relationshipInfo withData:localObjectData];
        
        if (relatedObject == nil)
        {
            NSEntityDescription *entityDescription = [relationshipInfo destinationEntity];
            relatedObject = [entityDescription QM_createInstanceInContext:[weakself managedObjectContext]];
        }
        [relatedObject QM_importValuesForKeysWithObject:localObjectData];
        
        if ((localObjectData) && (![localObjectData isKindOfClass:[NSDictionary class]]))
        {
			NSString * relatedByAttribute = [[relationshipInfo userInfo] objectForKey:kQMMagicalRecordImportRelationshipLinkedByKey] ?: QM_primaryKeyNameFromString([[relationshipInfo destinationEntity] name]);
			
            if (relatedByAttribute)
            {
				
                if (![relatedObject QM_importValue:localObjectData forKey:relatedByAttribute])
                {
                    [relatedObject setValue:localObjectData forKey:relatedByAttribute];
                }
				
            }
        }
        
        [weakself QM_addObject:relatedObject forRelationship:relationshipInfo];
	}];
}

+ (id) QM_importFromObject:(id)objectData inContext:(NSManagedObjectContext *)context;
{
    NSAttributeDescription *primaryAttribute = [[self QM_entityDescriptionInContext:context] QM_primaryAttributeToRelateBy];
    
    id value = [objectData QM_valueForAttribute:primaryAttribute];
    
    NSManagedObject *managedObject = nil;
    if (primaryAttribute != nil)
    {
        managedObject = [self QM_findFirstByAttribute:[primaryAttribute name] withValue:value inContext:context];
    }
    if (managedObject == nil)
    {
        managedObject = [self QM_createEntityInContext:context];
    }

    [managedObject QM_importValuesForKeysWithObject:objectData];

    return managedObject;
}

+ (id) QM_importFromObject:(id)objectData
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_importFromObject:objectData inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_importFromArray:(NSArray *)listOfObjectData
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [self QM_importFromArray:listOfObjectData inContext:[NSManagedObjectContext QM_contextForCurrentThread]];
#pragma clang diagnostic pop
}

+ (NSArray *) QM_importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *dataObjects = [NSMutableArray array];

    [listOfObjectData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *objectData = (NSDictionary *)obj;

        NSManagedObject *dataObject = [self QM_importFromObject:objectData inContext:context];

        [dataObjects addObject:dataObject];
    }];

    return dataObjects;
}

@end
