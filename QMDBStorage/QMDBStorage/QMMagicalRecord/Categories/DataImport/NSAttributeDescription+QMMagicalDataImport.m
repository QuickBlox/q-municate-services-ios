//
//  NSAttributeDescription+QMMagicalDataImport.m
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import "NSAttributeDescription+QMMagicalDataImport.h"
#import "NSManagedObject+QMMagicalDataImport.h"
#import "QMMagicalImportFunctions.h"

@implementation NSAttributeDescription (QMMagicalRecord_DataImport)

- (NSString *) QM_primaryKey;
{
    return nil;
}

- (id) QM_valueForKeyPath:(NSString *)keyPath fromObjectData:(id)objectData;
{
    id value = [objectData valueForKeyPath:keyPath];
    
    NSAttributeType attributeType = [self attributeType];
    NSString *desiredAttributeType = [[self userInfo] valueForKey:kQMMagicalRecordImportAttributeValueClassNameKey];
    if (desiredAttributeType) 
    {
        if ([desiredAttributeType hasSuffix:@"Color"])
        {
            value = colorFromString(value);
        }
    }
    else 
    {
        if (attributeType == NSDateAttributeType)
        {
            if (![value isKindOfClass:[NSDate class]]) 
            {
                NSString *dateFormat = [[self userInfo] valueForKey:kQMMagicalRecordImportCustomDateFormatKey];
                if ([value isKindOfClass:[NSNumber class]]) {
                    value = QM_dateFromNumber(value, [dateFormat isEqualToString:kQMMagicalRecordImportUnixTimeString]);
                }
                else {
                    value = QM_dateFromString([value description], dateFormat ?: kQMMagicalRecordImportDefaultDateFormatString);
                }
            }
        }
        else if (attributeType == NSInteger16AttributeType ||
                 attributeType == NSInteger32AttributeType ||
                 attributeType == NSInteger64AttributeType ||
                 attributeType == NSDecimalAttributeType ||
                 attributeType == NSDoubleAttributeType ||
                 attributeType == NSFloatAttributeType) {
            if (![value isKindOfClass:[NSNumber class]] && value != [NSNull null]) {
                value = QM_numberFromString([value description]);
            }
        }
        else if (attributeType == NSBooleanAttributeType) {
            if (![value isKindOfClass:[NSNumber class]] && value != [NSNull null]) {
            value = [NSNumber numberWithBool:[value boolValue]];
            }
        }
        else if (attributeType == NSStringAttributeType) {
            if (![value isKindOfClass:[NSString class]] && value != [NSNull null]) {
                value = [value description];
            }
        }
    }
    
    return value == [NSNull null] ? nil : value;   
}

@end
