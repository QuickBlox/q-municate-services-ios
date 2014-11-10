//
//  QMMagicalRecord+ErrorHandling.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord+ErrorHandling.h"
#import "QMMagicalRecordLogging.h"


__weak static id errorHandlerTarget = nil;
static SEL errorHandlerAction = nil;


@implementation QMMagicalRecord (ErrorHandling)

+ (void) cleanUpErrorHanding;
{
    errorHandlerTarget = nil;
    errorHandlerAction = nil;
}

+ (void) defaultErrorHandler:(NSError *)error
{
    NSDictionary *userInfo = [error userInfo];
    for (NSArray *detailedError in [userInfo allValues])
    {
        if ([detailedError isKindOfClass:[NSArray class]])
        {
            for (NSError *e in detailedError)
            {
                if ([e respondsToSelector:@selector(userInfo)])
                {
                    QMMRLogError(@"Error Details: %@", [e userInfo]);
                }
                else
                {
                    QMMRLogError(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            QMMRLogError(@"Error: %@", detailedError);
        }
    }
    QMMRLogError(@"Error Message: %@", [error localizedDescription]);
    QMMRLogError(@"Error Domain: %@", [error domain]);
    QMMRLogError(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

+ (void) handleErrors:(NSError *)error
{
	if (error)
	{
        // If a custom error handler is set, call that
        if (errorHandlerTarget != nil && errorHandlerAction != nil) 
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [errorHandlerTarget performSelector:errorHandlerAction withObject:error];
#pragma clang diagnostic pop
        }
		else
		{
	        // Otherwise, fall back to the default error handling
	        [self defaultErrorHandler:error];			
		}
    }
}

+ (id) errorHandlerTarget
{
    return errorHandlerTarget;
}

+ (SEL) errorHandlerAction
{
    return errorHandlerAction;
}

+ (void) setErrorHandlerTarget:(id)target action:(SEL)action
{
    errorHandlerTarget = target;    /* Deliberately don't retain to avoid potential retain cycles */
    errorHandlerAction = action;
}

- (void) handleErrors:(NSError *)error
{
	[[self class] handleErrors:error];
}

@end
