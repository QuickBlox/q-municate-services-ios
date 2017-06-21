//
//  QMOpenGraphService.m
//  QMOpenGraphService
//
//  Created by Andrey Ivanov on 14/06/2017.
//  Copyright © 2017 QuickBlox. All rights reserved.
//

#import "QMOpenGraphService.h"

static NSString *const kQMBaseGraphURL = @"https://ogs.quickblox.com";
static NSString *const kQMKeyTitle = @"ogTitle";
static NSString *const kQMKeyDescription = @"ogDescription";
static NSString *const kQMKeyImageURL = @"ogImage";

@interface QMOpenGraphService()

@property (nonatomic) NSMutableDictionary<NSString *, id> *links;

@property (strong, nonatomic) QBMulticastDelegate <QMOpenGraphServiceDelegate> *multicastDelegate;
@property (nonatomic, weak) id <QMOpenGraphCacheDataSource> cahceDataSource;
@property (nonatomic) QBHTTPClient *ogsClient;
@property (nonatomic) NSOperationQueue *operationQueue;

@end

@implementation QMOpenGraphService

- (instancetype)initWithCacheDataSource:(id<QMOpenGraphCacheDataSource>)cacheDataSource{
    
    if (self = [super init]) {
        
        _cahceDataSource = cacheDataSource;
        _memoryStorage = [[QMOpenGraphMemoryStorage alloc] init];
        _multicastDelegate = (id<QMOpenGraphServiceDelegate>)[[QBMulticastDelegate alloc] init];
        
        _links = [NSMutableDictionary dictionary];
        
        _ogsClient = [[QBHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kQMBaseGraphURL]];
        _ogsClient.completionQueue = dispatch_queue_create("com.q-municate.ogs", DISPATCH_QUEUE_SERIAL);
        
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)addDelegate:(id <QMOpenGraphServiceDelegate>)delegate {
    [_multicastDelegate addDelegate:delegate];
}

- (void)removeDelegate:(id <QMOpenGraphServiceDelegate>)delegate {
    [_multicastDelegate addDelegate:delegate];
}

- (void)loadOpenGraphForURL:(NSString *)url ID:(NSString *)ID {
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        QMOpenGraphItem *item = [self.memoryStorage openGraphItemWithBaseURL:url];
//        NSParameterAssert(!self.memoryStorage[ID]);
        if (item) {
            
            item = [item copy];
//            NSParameterAssert(![item.ID isEqualToString:ID]);
            item.ID = ID;
            self.memoryStorage[ID] = item;
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [self.multicastDelegate openGraphSerivce:self
                          didAddOpenGraphItemToMemoryStorage:item];
                NSLog(@"ID: %@, url %@ - exists", ID, url);
            });
            
            return;
        }
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        __weak __typeof(self)weakSelf = self;
        
        QBRequest *request =
        [self.ogsClient GET:@""
                 parameters:@{@"url": url}
                   progress:nil
                    success:^(NSURLSessionDataTask *task, NSData *responseObject)
         {
             //serial queue (com.q-municate.ogs)
             NSError *jsonError = nil;
             NSDictionary * jsonObject =
             [NSJSONSerialization JSONObjectWithData:responseObject
                                             options:NSJSONReadingAllowFragments
                                               error:&jsonError];
             if (jsonObject) {
                 
                 QMOpenGraphItem *openGraphItem =
                 [weakSelf openGraphWithID:ID dictionary:jsonObject baseUrl:url];
                 // Load Preview image
                 if (openGraphItem.imageURL) {
                     
//                     NSURL *previewImageURL = [NSURL URLWithString:openGraphItem.imageURL];
//                     NSData *previewImageData = [NSData dataWithContentsOfURL:previewImageURL];
//                     
//                     if (previewImageData) {
//                         
//                         UIImage *previewImage = [UIImage imageWithData:previewImageData];
//                         if (previewImage) {
//                             dispatch_sync(dispatch_get_main_queue(), ^{
//                                 [weakSelf.multicastDelegate openGraphSerivce:weakSelf
//                                                          didLoadPreviewImage:previewImage
//                                                                       forURL:previewImageURL];
//                             });
//                         }
//                         
//                         NSLog(@"--->: %tu, Finish load preview image %@",
//                               task.taskIdentifier,
//                               previewImageURL.absoluteString);
//                     }
//                     else {
//                         NSLog(@"--->: %tu, Filed load preview image %@",
//                               task.taskIdentifier,
//                               previewImageURL.absoluteString);
//                     }
                     
                 }
                 // Load favicon
                 NSURL *faviconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/favicon.ico", url]];
                 NSData *faviconData = [NSData dataWithContentsOfURL:faviconURL];
                 UIImage *faviconImage = [UIImage imageWithData:faviconData];
                 
                 if (faviconImage) {
                     NSLog(@"--->: %tu, Finish load favicon %@",
                           task.taskIdentifier, faviconURL.absoluteString);
                     
                     if (faviconImage) {
                         dispatch_sync(dispatch_get_main_queue(), ^{
                             [weakSelf.multicastDelegate openGraphSerivce:weakSelf
                                                           didLoadFavicon:faviconImage
                                                                   forURL:faviconURL];
                         });
                     }
                 }
                 else {
                     NSLog(@"--->: %tu, Filed load favicon %@",
                           task.taskIdentifier,
                           faviconURL.absoluteString);
                 }
                 
                 weakSelf.memoryStorage[ID] = openGraphItem;
                 
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     
                     [weakSelf.multicastDelegate openGraphSerivce:weakSelf
                               didAddOpenGraphItemToMemoryStorage:openGraphItem];
                 });
                 
                 dispatch_semaphore_signal(sem);
             }
             
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             
             NSLog(@"Failure task %tu, error - %@", task.taskIdentifier, error.localizedDescription);
             dispatch_semaphore_signal(sem);
         }];
        
        NSLog(@"Task: %tu, ID: %@, load for %@", request.task.taskIdentifier, ID, url);
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        NSLog(@"Done: %tu, ID: %@, %@", request.task.taskIdentifier, ID, url);
    }];
    
    [_operationQueue addOperation:operation];
}

- (BOOL)isLoaded {
    return NO;
}

- (void)openGraphItemForText:(NSString *)text ID:(NSString *)ID {
    
    if (text.length == 0) {
        return;
    }
    
    QMOpenGraphItem *openGraphItem = self.memoryStorage[ID];
    
    if (!openGraphItem) {
        
        NSDataDetector *detector =
        [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                        error:nil];
        
        NSRange textRenge = NSMakeRange(0, text.length);
        NSTextCheckingResult *result = [detector firstMatchInString:text options:0 range:textRenge];
        
        if (!result ||
            result.range.location > 0 ||
            result.range.length != text.length) {
            
            _links[ID] = [NSNull null];
        }
        else if ([self.cahceDataSource
             respondsToSelector:@selector(cachedOpenGraphItemWithID:URLString:)]) {
            
            openGraphItem = [self.cahceDataSource cachedOpenGraphItemWithID:ID
                                                                  URLString:result.URL.absoluteString];
            if (openGraphItem) {
                self.memoryStorage[openGraphItem.ID] = openGraphItem;
                [self.multicastDelegate openGraphSerivce:self didLoadFromCache:openGraphItem];
            }
            else {
                [self loadOpenGraphForURL:result.URL.absoluteString.lowercaseString ID:ID];
            }
        }
    }
}

//MARK: - Helpers

- (QMOpenGraphItem *)openGraphWithID:(NSString *)ID
                          dictionary:(NSDictionary *)deserializedDictionary
                             baseUrl:(NSString *)baseUrl {
    
    QMOpenGraphItem *openGraphItem = [[QMOpenGraphItem alloc] init];
    
    openGraphItem.baseUrl = baseUrl;
    
    openGraphItem.faviconUrl = [NSString stringWithFormat:@"%@/favicon.ico", baseUrl];
    openGraphItem.ID = ID;
    
    if (![deserializedDictionary[kQMKeyTitle] isKindOfClass:[NSNull class]]) {
        
        openGraphItem.siteTitle = deserializedDictionary[kQMKeyTitle];
    }
    
    if (![deserializedDictionary[kQMKeyDescription] isKindOfClass:[NSNull class]]) {
        
        openGraphItem.siteDescription = deserializedDictionary[kQMKeyDescription];
    }
    
    if (![deserializedDictionary[kQMKeyImageURL] isKindOfClass:[NSNull class]]) {
        
        NSString *imagePath = deserializedDictionary[kQMKeyImageURL][@"url"];
        
        if (imagePath != nil) {
            
            NSString *imageURL = [self qm_standartitizedURLStringFromString:imagePath];
            NSString *prefix = [self qm_standartitizedURLStringFromString:baseUrl];
            
            imageURL = [imageURL stringByReplacingOccurrencesOfString:prefix withString:@""];
            imageURL = [self qm_standartitizedURLStringFromString:imageURL];
            
            NSString *result = [NSString stringWithFormat:@"%@/%@", baseUrl, imageURL];
            openGraphItem.imageURL = result;
        }
    }
    
    return openGraphItem;
}

- (NSString *)qm_standartitizedURLStringFromString:(NSString *)stringURL {
    
    NSArray *prefixes = @[@"https:", @"http:", @"//", @"/", @"www."];
    
    for (NSString *prefix in prefixes) {
        
        if ([stringURL hasPrefix:prefix]) {
            stringURL = [stringURL stringByReplacingOccurrencesOfString:prefix
                                                             withString:@""
                                                                options:NSAnchoredSearch
                                                                  range:NSMakeRange(0,stringURL.length)];
        }
    }
    
    return stringURL;
}

//MARK: - QMMemoryStorageProtocol

- (void)free {
    
    //    [_messagesWithoutLinks removeAllObjects];
    //    [_memoryStorage free];
    [_links removeAllObjects];
}

@end
