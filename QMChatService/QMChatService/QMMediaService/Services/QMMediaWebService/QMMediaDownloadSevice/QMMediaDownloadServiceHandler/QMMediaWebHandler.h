//
//  QMMediaWebHandler.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMMediaBlocks.h"

@protocol QMMediaDownloadDelegate;

@interface QMMediaWebHandler : NSObject

@property (nonatomic, copy) NSString *handlerID;
@property (nonatomic, copy) QMMediaProgressBlock progressBlock;
@property (nonatomic, copy) QMMediaRestCompletionBlock completionBlock;
@property (nonatomic, copy) QMMediaErrorBlock errorBlock;

@property (nonatomic, weak) id <QMMediaDownloadDelegate> delegate;

+ (QMMediaWebHandler *)downloadingHandlerWithID:(NSString *)handlerID
                                completionBlock:(QMMediaRestCompletionBlock)completionBlock
                                  progressBlock:(QMMediaProgressBlock)progressBlock;

+ (QMMediaWebHandler *)uploadingHandlerWithID:(NSString *)handlerID
                              completionBlock:(QMMediaRestCompletionBlock)completionBlock
                                progressBlock:(QMMediaProgressBlock)progressBlock;



@end

@interface QMMessageUploadHandler : NSObject

@property (nonatomic, copy) NSString *handlerID;
@property (nonatomic, copy) QMMessageUploadProgressBlock progressBlock;
@property (nonatomic, copy) QMMessageUploadCompletionBlock completionBlock;

@property (nonatomic, weak) id <QMMediaDownloadDelegate> delegate;

+ (QMMessageUploadHandler *)uploadingHandlerWithID:(NSString *)handlerID
                                   completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                                     progressBlock:(QMMessageUploadProgressBlock)progressBlock;

@end

