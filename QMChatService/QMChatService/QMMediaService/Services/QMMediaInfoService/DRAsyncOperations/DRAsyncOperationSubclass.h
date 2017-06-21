//
//  DRAsyncOperationSubclass.h
//  DRAsyncOperations
//
//  Created by David Rodrigues on 18/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import "DRAsyncOperation.h"

/**
 Extensions to be used by subclasses of \c DRAsyncOperation to encapsulate the code of an async task.
 
 The code that uses \c DRAsyncOperation must never call these methods.
 */
@interface DRAsyncOperation (DRAsyncOperationProtected)

/**
 Performs the receiver's asynchronous task.
 
 \b Discussion \n
 
 You must override this method to perform the desired asynchronous task but do not invoke \c super at any time. \n
 
 When the asynchronous task has completed, you must call \c -finish to mark his completion and terminate the operation.
 */
- (void)asyncTask;

/**
 Marks the completion of receiver's asynchronous task.
 */
- (void)finish NS_REQUIRES_SUPER;

@end
