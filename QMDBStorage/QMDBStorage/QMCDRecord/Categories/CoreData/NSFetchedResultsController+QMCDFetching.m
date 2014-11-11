//
//  NSFetchedResultsController+QMCDFetching.m
//  TradeShow
//
//  Created by Saul Mora on 2/5/13.
//  Copyright (c) 2013 QMCD Panda Software. All rights reserved.
//

#import "NSFetchedResultsController+QMCDFetching.h"
#import "NSError+QMCDRecordErrorHandling.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@implementation NSFetchedResultsController (QMCDFetching)

- (void) QM_performFetch;
{
    NSError *error = nil;
    BOOL success = [self performFetch:&error];
    
    if (!success)
    {
        [[error QM_coreDataDescription] QM_logToConsole];
    }
}

@end
#endif
