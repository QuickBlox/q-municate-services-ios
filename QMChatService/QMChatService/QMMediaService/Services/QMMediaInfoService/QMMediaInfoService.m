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
@property (strong, nonatomic,readwrite) NSMutableSet *attachmentsInProcess;

@end

@implementation QMMediaInfoService

//MARK: - NSObject

- (instancetype)init {
    
    if (self = [super init]) {
        
        _imagesOperationQueue = [[NSOperationQueue alloc] init];
        _imagesOperationQueue.maxConcurrentOperationCount  = 2;
        _imagesOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _imagesOperationQueue.name = @"QMServices.videoThumbnailOperationQueue";
        
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
    
    QMImageOperation *imageOperation =
    [[QMImageOperation alloc] initWithURL:attachment.remoteURL
                        completionHandler:^(UIImage * _Nullable image,
                                            Float64 durationSeconds,
                                            CGSize size,
                                            NSError * _Nullable error) {
                            
                            
                            if (completion) {
                                completion(image, error);
                            }
                        }];
    
    imageOperation.operationID = attachment.ID;
    [self.imagesOperationQueue addOperation:imageOperation];
    
}

- (void)cancellAllInfoOperations {
    
    [self.imagesOperationQueue cancelAllOperations];
}


- (void)cancelInfoOperationForKey:(NSString *)key {
    
    for (QMImageOperation *operationInQueue in self.imagesOperationQueue.operations) {
        if ([operationInQueue.operationID isEqualToString:key]) {
            [operationInQueue cancel];
        }
    }
    NSLog(@"Operation queue after cancell: %@",self.imagesOperationQueue.operations);
}


@end
