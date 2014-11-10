//
//  NSAttributeDescription+QMMagicalDataImport.h
//  QMMagical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 QMMagical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSAttributeDescription (QMMagicalRecord_DataImport)

- (NSString *) QM_primaryKey;
- (id) QM_valueForKeyPath:(NSString *)keyPath fromObjectData:(id)objectData;

@end
