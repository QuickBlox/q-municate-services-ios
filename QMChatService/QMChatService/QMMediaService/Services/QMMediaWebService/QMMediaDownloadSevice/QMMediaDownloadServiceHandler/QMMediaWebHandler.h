//
//  QMMediaWebHandler.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMRestAPIBlocks.h"

@protocol QMMediaDownloadDelegate;

@interface QMMediaWebHandler : NSObject

@property (nonatomic, copy) NSString *handlerID;
@property (nonatomic, copy) QMMediaProgressBlock progressBlock;
@property (nonatomic, copy) QMMediaRestCompletionBlock completionBlock;
@property (nonatomic, copy) QMMediaErrorBlock errorBlock;

@property (nonatomic, weak) id<QMMediaDownloadDelegate> delegate;

+ (QMMediaWebHandler *)downloadingHandlerWithID:(NSString *)handlerID
                                            progressBlock:(QMMediaProgressBlock)progressBlock
                                          completionBlock:(QMMediaRestCompletionBlock)completionBlock;

+ (QMMediaWebHandler *)downloadingHandlerWithID:(NSString *)handlerID
                                                 delegate:(id<QMMediaDownloadDelegate>)delegate;

+ (QMMediaWebHandler *)uploadingHandlerWithID:(NSString *)handlerID
                              progressBlock:(QMMediaProgressBlock)progressBlock
                            completionBlock:(QMMediaRestCompletionBlock)completionBlock;



@end

