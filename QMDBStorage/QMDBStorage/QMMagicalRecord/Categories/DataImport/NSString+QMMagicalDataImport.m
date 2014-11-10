//
//  NSString+QMMagicalRecord_QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 12/10/11.
//  Copyright (c) 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSString+QMMagicalDataImport.h"


@implementation NSString (QMMagicalRecord_DataImport)

- (NSString *) QM_capitalizedFirstCharacterString;
{
    if ([self length] > 0)
    {
        NSString *firstChar = [[self substringToIndex:1] capitalizedString];
        return [firstChar stringByAppendingString:[self substringFromIndex:1]];
    }
    return self;
}

- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    return self;
}

- (NSString *) QM_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo
{
    return nil;
}

@end

