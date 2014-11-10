//
//  NSNumber+QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSNumber+QMMagicalDataImport.h"



@implementation NSNumber (QMMagicalRecord_DataImport)

- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    return self;
}

- (NSString *) QM_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo
{
    return nil;
}

@end
