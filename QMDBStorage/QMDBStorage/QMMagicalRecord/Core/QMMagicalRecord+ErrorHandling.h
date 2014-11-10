//
//  QMMagicalRecord+ErrorHandling.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord.h"

@interface QMMagicalRecord (ErrorHandling)

+ (void) handleErrors:(NSError *)error;
- (void) handleErrors:(NSError *)error;

+ (void) setErrorHandlerTarget:(id)target action:(SEL)action;
+ (SEL) errorHandlerAction;
+ (id) errorHandlerTarget;

@end
