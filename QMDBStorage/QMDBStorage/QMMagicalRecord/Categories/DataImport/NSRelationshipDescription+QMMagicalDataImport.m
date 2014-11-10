//
//  NSRelationshipDescription+QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSRelationshipDescription+QMMagicalDataImport.h"
#import "NSManagedObject+QMMagicalDataImport.h"
#import "QMMagicalImportFunctions.h"
#import "QMMagicalRecord.h"

@implementation NSRelationshipDescription (QMMagicalRecord_DataImport)

- (NSString *) QM_primaryKey;
{
    NSString *primaryKeyName = [[self userInfo] valueForKey:kQMMagicalRecordImportRelationshipLinkedByKey] ?: 
    QM_primaryKeyNameFromString([[self destinationEntity] name]);
    
    return primaryKeyName;
}

@end
