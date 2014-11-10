//
//  QMMagicalRecord+ShorthandSupport.h
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord.h"

@interface QMMagicalRecord (ShorthandSupport)

#ifdef QM_SHORTHAND
+ (void) swizzleShorthandMethods;
#endif

@end
