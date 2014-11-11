//
//  NSNumber+QMCDDataImport.h
//  QMCD Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMCD Panda Software LLC. All rights reserved.
//

@interface NSNumber (QMCDRecordDataImport)

- (NSString *) QM_lookupKeyForProperty:(NSPropertyDescription *)propertyDescription;
- (id) QM_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo;

/**
 If possible, converts the current number into a data using the specified format string.
 See http://en.wikipedia.org/wiki/Date_(Unix) for usable date format specifiers.

 @param dateFormat String containing a UNIX date format string.

 @return The current number as a date.

 @since Available in v3.0 and later.
 */
- (NSDate *) QM_dateWithFormat:(NSString *)dateFormat;

@end
