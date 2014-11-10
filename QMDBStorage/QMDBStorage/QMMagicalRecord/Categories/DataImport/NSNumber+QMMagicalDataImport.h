//
//  NSNumber+QMMagicalDataImport.h
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSNumber (QMMagicalRecord_DataImport)

- (NSString *) QM_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

@end
