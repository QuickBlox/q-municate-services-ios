//
//  NSManagedObject+JSONHelpers.h
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const kQMMagicalRecordImportCustomDateFormatKey;
extern NSString * const kQMMagicalRecordImportDefaultDateFormatString;
extern NSString * const kQMMagicalRecordImportUnixTimeString;
extern NSString * const kQMMagicalRecordImportAttributeKeyMapKey;
extern NSString * const kQMMagicalRecordImportAttributeValueClassNameKey;

extern NSString * const kQMMagicalRecordImportRelationshipMapKey;
extern NSString * const kQMMagicalRecordImportRelationshipLinkedByKey;
extern NSString * const kQMMagicalRecordImportRelationshipTypeKey;

@protocol QMMagicalRecordDataImportProtocol <NSObject>

@optional
- (BOOL) shouldImport:(id)data;
- (void) willImport:(id)data;
- (void) didImport:(id)data;

@end

@interface NSManagedObject (QMMagicalRecord_DataImport) <QMMagicalRecordDataImportProtocol>

- (BOOL) QM_importValuesForKeysWithObject:(id)objectData;

+ (instancetype) QM_importFromObject:(id)data;
+ (instancetype) QM_importFromObject:(id)data inContext:(NSManagedObjectContext *)context;

+ (NSArray *) QM_importFromArray:(NSArray *)listOfObjectData;
+ (NSArray *) QM_importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context;

@end
