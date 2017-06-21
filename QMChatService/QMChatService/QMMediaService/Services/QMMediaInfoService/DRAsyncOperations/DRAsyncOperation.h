//
//  DRAsyncOperation.h
//  DRAsyncOperations
//
//  Created by David Rodrigues on 17/04/15.
//  Copyright (c) 2015 David Rodrigues. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The \c DRAsyncOperation is an abstract class to encapsulate and manage execution of an asynchronous task in a very 
 similar way as a common \c NSOperation. Because it is abstract, this class should not be used directly but instead
 subclass to implement the asynchronous task.
 
 To subclass and implement an async task please refer to \c DRAsyncOperationSubclass.
 */
@interface DRAsyncOperation : NSOperation

@end
