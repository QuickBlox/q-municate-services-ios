//
//  NSRelationshipDescription+QMCDDataImport.m
//  QMCD Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMCD Panda Software LLC. All rights reserved.
//

#import "NSRelationshipDescription+QMCDDataImport.h"
#import "NSManagedObject+QMCDDataImport.h"
#import "QMCDImportFunctions.h"
#import "QMCDRecord.h"

@implementation NSRelationshipDescription (QMCDRecordDataImport)

- (NSString *) QM_primaryKey;
{
    NSString *primaryKeyName = [[self userInfo] valueForKey:kQMCDRecordImportDistinctAttributeKey] ?: 
    MRPrimaryKeyNameFromString([[self destinationEntity] name]);
    
    return primaryKeyName;
}

@end
