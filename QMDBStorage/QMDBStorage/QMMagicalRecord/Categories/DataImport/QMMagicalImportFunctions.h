//
//  QMMagicalImportFunctions.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


NSDate * QM_adjustDateForDST(NSDate *date);
NSDate * QM_dateFromString(NSString *value, NSString *format);
NSDate * QM_dateFromNumber(NSNumber *value, BOOL milliseconds);
NSNumber * QM_numberFromString(NSString *value);
NSString * QM_attributeNameFromString(NSString *value);
NSString * QM_primaryKeyNameFromString(NSString *value);

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
UIColor * QM_colorFromString(NSString *serializedColor);
#else
#import <AppKit/AppKit.h>
NSColor * QM_colorFromString(NSString *serializedColor);
#endif

NSInteger* QM_newColorComponentsFromString(NSString *serializedColor);
extern id (*colorFromString)(NSString *);
