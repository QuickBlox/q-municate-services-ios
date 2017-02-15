//
//  QMMediaWebHandler.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaWebHandler.h"
#import "QMMediaDownloadServiceDelegate.h"

@interface QMMediaWebHandler()

@end

@implementation QMMediaWebHandler

+ (QMMediaWebHandler *)downloadingHandlerWithID:(NSString *)handlerID
                                completionBlock:(QMMediaRestCompletionBlock)completionBlock
                                  progressBlock:(QMMediaProgressBlock)progressBlock {
    
    QMMediaWebHandler *mediaHandler = [QMMediaWebHandler new];
    mediaHandler.handlerID = handlerID;
    mediaHandler.progressBlock = progressBlock;
    mediaHandler.completionBlock = completionBlock;
    
    return mediaHandler;
}

+ (QMMediaWebHandler *)downloadingHandlerWithMediaID:(NSString *)handlerID
                                            delegate:(id <QMMediaDownloadDelegate>)delegate {
    
    QMMediaWebHandler *mediaHandler = [QMMediaWebHandler new];
    
    mediaHandler.handlerID = handlerID;
    mediaHandler.delegate = delegate;
    
    return mediaHandler;
}

+ (QMMediaWebHandler *)uploadingHandlerWithID:(NSString *)handlerID
                              completionBlock:(QMMediaRestCompletionBlock)completionBlock
                                progressBlock:(QMMediaProgressBlock)progressBlock {
    
    QMMediaWebHandler *mediaHandler = [QMMediaWebHandler new];
    mediaHandler.handlerID = handlerID;
    mediaHandler.progressBlock = progressBlock;
    mediaHandler.completionBlock = completionBlock;
    
    return mediaHandler;
}

@end

@implementation QMMessageUploadHandler

+ (QMMessageUploadHandler *)uploadingHandlerWithID:(NSString *)handlerID
                                   completionBlock:(QMMessageUploadCompletionBlock)completionBlock
                                     progressBlock:(QMMessageUploadProgressBlock)progressBlock {
    
    QMMessageUploadHandler *mediaHandler = [QMMessageUploadHandler new];
    mediaHandler.handlerID = handlerID;
    mediaHandler.progressBlock = progressBlock;
    mediaHandler.completionBlock = completionBlock;
    
    return mediaHandler;
}

@end

