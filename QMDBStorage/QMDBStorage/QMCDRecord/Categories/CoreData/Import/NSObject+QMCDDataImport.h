//
//  NSDictionary+QMCDDataImport.h
//  QMCD Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMCD Panda Software LLC. All rights reserved.
//

@interface NSObject (QMCDRecordDataImport)

- (NSString *) QM_lookupKeyForProperty:(NSPropertyDescription *)propertyDescription;
- (id) QM_valueForAttribute:(NSAttributeDescription *)attributeInfo;

- (NSString *) QM_lookupKeyForRelationship:(NSRelationshipDescription *)relationshipInfo;
- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

@end
