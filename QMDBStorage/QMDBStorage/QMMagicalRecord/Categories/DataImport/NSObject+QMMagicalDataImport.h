//
//  NSDictionary+QMMagicalDataImport.h
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSObject (QMMagicalRecord_DataImport)

- (NSString *) QM_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo;
- (id) QM_valueForAttribute:(NSAttributeDescription *)attributeInfo;

- (NSString *) QM_lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo;
- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

@end
