//
//  QMMediaDownloadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "EXTScope.h"

#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaDownloadDelegate.h"

#import "QMMediaDownloadService.h"

#import "QMRestAPIBlocks.h"

#import "QMMediaWebHandler.h"

#import <QuickBlox/QBMulticastDelegate.h>
#import "QMSLog.h"

@interface QMMediaDownloadService()

@property (strong, nonatomic) QBMulticastDelegate <QMMediaDownloadDelegate> *multicastDelegate;
@property (strong, nonatomic) QMChatAttachmentService *attachmentService;
@property (strong, nonatomic) NSMutableDictionary *downloadHandlers;

@end

@implementation QMMediaDownloadService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _multicastDelegate = (id <QMMediaDownloadDelegate>)[[QBMulticastDelegate alloc] init];
        _attachmentService = [[QMChatAttachmentService alloc] init];
        _downloadHandlers = [NSMutableDictionary dictionary];
        
    }
    
    return self;
}


- (void)downloadMediaItemWithID:(NSString *)mediaID
            withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                  progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self addListenerToMediaItemWithID:mediaID withCompletionBlock:completionBlock progressBlock:progressBlock];
    [self downloadMediaItemWithID:mediaID delegate:nil];
}

- (void)downloadMediaItemWithID:(NSString *)mediaID
                       delegate:(id <QMMediaDownloadDelegate>)delegate {
    
    if (delegate) {
        [self.multicastDelegate addDelegate:delegate];
    }
    
    [QBRequest downloadFileWithUID:mediaID  successBlock:^(QBResponse *response, NSData *fileData) {
        if (fileData) {
            globalCompletionBlock(mediaID, fileData, nil, self);
        }
    } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
        
        globalProgressBlock(mediaID,status.percentOfCompletion, self);
        
    } errorBlock:^(QBResponse *response) {
        
        globalCompletionBlock(mediaID, nil, response.error.error, self);
    }];
}


//MARK: - Listeners

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                            delegate:(id <QMMediaDownloadDelegate>)delegate {
    
    NSMutableArray *handlers = [self.downloadHandlers objectForKey:mediaID];
    
    if (handlers == nil) {
        handlers = [NSMutableArray new];
    }
    
    QMMediaWebHandler *handler = [QMMediaWebHandler downloadingHandlerWithID:mediaID delegate:delegate];
    
    [handlers addObject:handler];
    [self.downloadHandlers setObject:handlers forKey:mediaID];
}

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                 withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                       progressBlock:(QMMediaProgressBlock)progressBlock {
    
    NSMutableArray *handlers = [self.downloadHandlers objectForKey:mediaID];
    
    if (handlers == nil) {
        handlers = [NSMutableArray new];
    }
    
    QMMediaWebHandler *handler = [QMMediaWebHandler downloadingHandlerWithID:mediaID progressBlock:progressBlock completionBlock:completionBlock];
    
    [handlers addObject:handler];
    [self.downloadHandlers setObject:handlers forKey:mediaID];
}


//MARK:-  Global Blocks

void (^globalProgressBlock)(NSString *mediaID, float progress, QMMediaDownloadService *downloadService) =
^(NSString *mediaID, float progress, QMMediaDownloadService *downloadService)
{
    NSMutableArray *handlers = [downloadService.downloadHandlers objectForKey:mediaID];
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
        if(handler.progressBlock) {
            handler.progressBlock(progress);
        }
        
        if([handler.delegate respondsToSelector:@selector(didUpdateDownloadingProgress:forMediaWithID:)]) {
            [handler.delegate didUpdateDownloadingProgress:progress forMediaWithID:mediaID];
        }
    }];
    
    [downloadService.multicastDelegate didUpdateDownloadingProgress:progress forMediaWithID:mediaID];
};


void (^globalCompletionBlock)(NSString *mediaID, NSData *data, NSError *error, QMMediaDownloadService *downloadService) =
^(NSString *mediaID, NSData *data, NSError *error, QMMediaDownloadService *downloadService)
{
    NSMutableArray *handlers = [downloadService.downloadHandlers objectForKey:mediaID];

    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
        if (handler.completionBlock) {
            handler.completionBlock(mediaID, data, error);
        }
        
        if ([handler.delegate respondsToSelector:@selector(didEndDownloadingMediaWithID:mediaData:error:)]) {
            [handler.delegate didEndDownloadingMediaWithID:mediaID mediaData:data error:error];
        }
        
    }];
    
    [downloadService.downloadHandlers removeObjectForKey:mediaID];
    
    [downloadService.multicastDelegate didEndDownloadingMediaWithID:mediaID mediaData:data error:error];
};



@end
