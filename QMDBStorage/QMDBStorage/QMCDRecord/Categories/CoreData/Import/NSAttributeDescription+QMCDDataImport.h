//
//  NSAttributeDescription+QMCDDataImport.h
//  QMCD Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMCD Panda Software LLC. All rights reserved.
//

@interface NSAttributeDescription (QMCDRecordDataImport)

- (NSString *) QM_primaryKey;
- (id) QM_valueForKeyPath:(NSString *)keyPath fromObjectData:(id)objectData;

- (BOOL) QM_shouldUseDefaultValueIfNoValuePresent;

@end
