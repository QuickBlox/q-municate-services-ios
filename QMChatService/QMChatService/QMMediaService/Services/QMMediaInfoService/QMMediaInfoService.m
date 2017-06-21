//
//  QMMediaInfoService.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 2/22/17.
//
//

#import "QMMediaInfoService.h"
#import <AVKit/AVKit.h>
#import "QMImageOperation.h"
#import "DRAsyncBlockOperation.h"
#import "QBChatAttachment+QMCustomParameters.h"

@interface QMMediaInfoService()

@property (strong, nonatomic) NSOperationQueue *imagesOperationQueue;
@property (strong, nonatomic) NSMutableSet *imageOperations;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _imagesOperationQueue = [[NSOperationQueue alloc] init];
        _imagesOperationQueue.maxConcurrentOperationCount  = 2;
        _imagesOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _imagesOperationQueue.name = @"QMServices.videoThumbnailOperationQueue";
        
        _imageOperations = [NSMutableSet set];
    }
    
    return self;
}

- (void)videoThumbnailForAttachment:(QBChatAttachment *)attachment
                         completion:(void(^)(UIImage *image, NSError *error))completion {
    
    NSURL *remoteURL = attachment.remoteURL;
    if (!remoteURL) {
        return;
    }
    for (QMImageOperation *operationInQueue in self.imagesOperationQueue.operations) {
        if ([operationInQueue.operationID isEqualToString:attachment.ID]) {
            return;
        }
    }
    
    [self.imageOperations addObject:attachment.ID];
    
    QMImageOperation *imageOperation =
    [[QMImageOperation alloc] initWithURL:attachment.remoteURL
                        completionHandler:^(UIImage * _Nullable image,
                                            Float64 durationSeconds,
                                            CGSize size,
                                            NSError * _Nullable error) {
                            
                            [self.imageOperations removeObject:attachment.ID];
                            if (completion) {
                                completion(image, error);
                            }
                        }];
    
    imageOperation.operationID = attachment.ID;
    [self.imagesOperationQueue addOperation:imageOperation];
    
}

- (void)cancellAllInfoOperations {
    
    [self.imagesOperationQueue cancelAllOperations];
    [self.imageOperations removeAllObjects];
}


- (void)cancelInfoOperationForKey:(NSString *)key {
    return;
    NSLog(@"Operation queue before cancell: %@",self.imagesOperationQueue.operations);
    for (QMImageOperation *operationInQueue in self.imagesOperationQueue.operations) {
        if ([operationInQueue.operationID isEqualToString:key]) {
            [self.imageOperations removeObject:key];
            [operationInQueue cancel];
        }
    }
    NSLog(@"Operation queue after cancell: %@",self.imagesOperationQueue.operations);
}


@end
