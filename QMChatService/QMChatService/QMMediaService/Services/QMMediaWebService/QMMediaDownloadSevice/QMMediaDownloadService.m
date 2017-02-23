//
//  QMMediaDownloadService.m
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/7/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

#import "QMMediaDownloadServiceDelegate.h"
#import "QMMediaDownloadDelegate.h"


#import "QMMediaDownloadService.h"

#import "QMMediaBlocks.h"

#import "QMMediaWebHandler.h"

#import <QuickBlox/QBMulticastDelegate.h>
#import "QMSLog.h"

#import "QMMediaError.h"

@interface QMMediaDownloadService()

@property (strong, nonatomic) QBMulticastDelegate <QMMediaDownloadDelegate> *multicastDelegate;
@property (strong, nonatomic) NSMutableDictionary *downloadHandlers;


@property (strong, nonatomic) dispatch_queue_t barrierQueue;

@end

@implementation QMMediaDownloadService

- (void)dealloc {
    
    QMSLog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _multicastDelegate = (id <QMMediaDownloadDelegate>)[[QBMulticastDelegate alloc] init];
        _downloadHandlers = [NSMutableDictionary dictionary];
        _barrierQueue = dispatch_queue_create("com.quickblox.QMMediaDownloadService", DISPATCH_QUEUE_CONCURRENT);
        
    }
    
    return self;
}


- (void)downloadMediaItemWithID:(NSString *)mediaID
            withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                  progressBlock:(QMMediaProgressBlock)progressBlock {
    
    [self addListenerToMediaItemWithID:mediaID
                   withCompletionBlock:completionBlock
                         progressBlock:progressBlock];
    
    [QBRequest downloadFileWithUID:mediaID  successBlock:^(QBResponse *response, NSData *fileData) {
        
        if (fileData) {
            
            globalCompletionBlock(mediaID, fileData, nil, self);
        }
    } statusBlock:^(QBRequest *request, QBRequestStatus *status) {
        
        globalProgressBlock(mediaID, status.percentOfCompletion, self);
        
    } errorBlock:^(QBResponse *response) {
        
        QMMediaError *error = [QMMediaError errorWithResponse:response];
        globalCompletionBlock(mediaID, nil, error, self);
    }];
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
        QMMediaError *error = [QMMediaError errorWithResponse:response];
        globalCompletionBlock(mediaID, nil, error, self);
        
    }];
}


//MARK: - Listeners

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                            delegate:(id <QMMediaDownloadDelegate>)delegate {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableArray *handlers = self.downloadHandlers[mediaID];
        
        if (handlers == nil) {
            handlers = [NSMutableArray new];
        }
        
        QMMediaWebHandler *handler = [QMMediaWebHandler downloadingHandlerWithID:mediaID
                                                                        delegate:delegate];
        
        [handlers addObject:handler];
        strongSelf.downloadHandlers[mediaID] = handlers;
    });
}

- (void)addListenerToMediaItemWithID:(NSString *)mediaID
                 withCompletionBlock:(QMMediaRestCompletionBlock)completionBlock
                       progressBlock:(QMMediaProgressBlock)progressBlock {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        NSMutableArray *handlers = self.downloadHandlers[mediaID];
        
        if (handlers == nil) {
            handlers = [NSMutableArray new];
        }
        
        QMMediaWebHandler *handler = [QMMediaWebHandler downloadingHandlerWithID:mediaID
                                                                 completionBlock:completionBlock
                                                                   progressBlock:progressBlock];
        
        [handlers addObject:handler];
        strongSelf.downloadHandlers[mediaID] = handlers;
    });
}


//MARK:-  Global Blocks

void (^globalProgressBlock)(NSString *mediaID, float progress, QMMediaDownloadService *downloadService) =
^(NSString *mediaID, float progress, QMMediaDownloadService *downloadService)
{
    
    __block NSArray *handlers;
    
    dispatch_sync(downloadService.barrierQueue, ^{
        handlers = [[downloadService.downloadHandlers objectForKey:mediaID] copy];
    });
    
    //Inform the handlers
    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler.progressBlock) {
                handler.progressBlock(progress);
            }
            
            if([handler.delegate respondsToSelector:@selector(didUpdateDownloadingProgress:forMediaWithID:)]) {
                [handler.delegate didUpdateDownloadingProgress:progress forMediaWithID:mediaID];
            }
        });
    }];
    
    [downloadService.multicastDelegate didUpdateDownloadingProgress:progress forMediaWithID:mediaID];
};


void (^globalCompletionBlock)(NSString *mediaID, NSData *data, QMMediaError *error, QMMediaDownloadService *downloadService) =
^(NSString *mediaID, NSData *data, QMMediaError *error, QMMediaDownloadService *downloadService)
{
    __block NSArray *handlers;
    
    dispatch_barrier_sync(downloadService.barrierQueue, ^{
        handlers = [[downloadService.downloadHandlers objectForKey:mediaID] copy];
        [downloadService.downloadHandlers removeObjectForKey:mediaID];
    });
    
    [handlers enumerateObjectsUsingBlock:^(QMMediaWebHandler *handler, NSUInteger idx, BOOL *stop) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (handler.completionBlock) {
                handler.completionBlock(mediaID, data, error);
            }
            
            if ([handler.delegate respondsToSelector:@selector(didEndDownloadingMediaWithID:mediaData:error:)]) {
                [handler.delegate didEndDownloadingMediaWithID:mediaID mediaData:data error:error];
            }
        });
    }];
    
    
    [downloadService.multicastDelegate didEndDownloadingMediaWithID:mediaID mediaData:data error:error];
};



@end
