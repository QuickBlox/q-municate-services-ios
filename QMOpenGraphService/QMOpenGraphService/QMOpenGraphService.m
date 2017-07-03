//
//  QMOpenGraphService.m
//  QMOpenGraphService
//
//  Created by Andrey Ivanov on 14/06/2017.
//  Copyright © 2017 QuickBlox. All rights reserved.
//

#import "QMOpenGraphService.h"

@interface QMOpenGraphLoadOperation : NSBlockOperation

@property (nonatomic) NSString *identifier;

@end

static NSString *const kQMBaseGraphURL = @"https://ogs.quickblox.com";
static NSString *const kQMKeyTitle = @"ogTitle";
static NSString *const kQMKeyDescription = @"ogDescription";
static NSString *const kQMKeyImageURL = @"ogImage";

@interface QMOpenGraphService()

@property (strong, nonatomic) QBMulticastDelegate <QMOpenGraphServiceDelegate> *multicastDelegate;
@property (nonatomic, weak) id <QMOpenGraphCacheDataSource> cahceDataSource;
@property (nonatomic) QBHTTPClient *ogsClient;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) dispatch_queue_t ogsQueue;

@end

@implementation QMOpenGraphService

- (instancetype)initWithCacheDataSource:(id<QMOpenGraphCacheDataSource>)cacheDataSource{
    
    if (self = [super init]) {
        
        _cahceDataSource = cacheDataSource;
        _memoryStorage = [[QMOpenGraphMemoryStorage alloc] init];
        _multicastDelegate = (id<QMOpenGraphServiceDelegate>)[[QBMulticastDelegate alloc] init];
        _ogsClient = [[QBHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kQMBaseGraphURL]];
        _ogsClient.completionQueue = dispatch_queue_create("com.q-municate.ogsClient", DISPATCH_QUEUE_SERIAL);
        _ogsQueue = dispatch_queue_create("com.q-municate.ogs", DISPATCH_QUEUE_CONCURRENT);
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
    
    for (QMOpenGraphLoadOperation *o in _operationQueue.operations) {
        
        if ([o.identifier isEqualToString:ID]) {
            return;
        }
    }
    
    QMOpenGraphLoadOperation *operation = [[QMOpenGraphLoadOperation alloc] init];
    operation.identifier = ID;
    [operation addExecutionBlock:^{

        QMOpenGraphItem *item = [self.memoryStorage openGraphItemWithBaseURL:url];
        //NSParameterAssert(!self.memoryStorage[ID]);
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
                     
                     NSURL *previewImageURL = [NSURL URLWithString:openGraphItem.imageURL];
                     NSData *previewImageData = [NSData dataWithContentsOfURL:previewImageURL];
                     
                     if (previewImageData) {
                         
                         UIImage *previewImage = [UIImage imageWithData:previewImageData];
                         if (previewImage) {
                             dispatch_sync(dispatch_get_main_queue(), ^{
                                 [weakSelf.multicastDelegate openGraphSerivce:weakSelf
                                                          didLoadPreviewImage:previewImage
                                                                       forURL:previewImageURL];
                             });
                         }
                         
                         NSLog(@"--->: %tu, Finish load preview image %@",
                               task.taskIdentifier,
                               previewImageURL.absoluteString);
                     }
                     else {
                         NSLog(@"--->: %tu, Filed load preview image %@",
                               task.taskIdentifier,
                               previewImageURL.absoluteString);
                     }
                     
                 }
                 // Load favicon
                 NSURL *faviconURL = [NSURL URLWithString:openGraphItem.faviconUrl];
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
    
    NSLog(@"Add: %@, %@", operation, url);
    [_operationQueue addOperation:operation];
}

- (void)cancelAllloads {
    
    [self.operationQueue cancelAllOperations];
}

- (void)preloadGraphItemForText:(NSString *)text ID:(NSString *)ID {
    
    if (text.length == 0 || ID.length == 0) {
        return;
    }
    
    QMOpenGraphItem *openGraphItem = self.memoryStorage[ID];
    
    if (!openGraphItem) {
        
        if ([self.cahceDataSource
             respondsToSelector:@selector(cachedOpenGraphItemWithID:)]) {
            
            openGraphItem = [self.cahceDataSource cachedOpenGraphItemWithID:ID];
            
            if (openGraphItem) {
                self.memoryStorage[openGraphItem.ID] = openGraphItem;
                [self.multicastDelegate openGraphSerivce:self didLoadFromCache:openGraphItem];
            }
            else {
                
                dispatch_async(_ogsQueue, ^{
                    
                    NSDataDetector *detector =
                    [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                    error:nil];
                    
                    NSRange textRenge = NSMakeRange(0, text.length);
                    NSTextCheckingResult *result = [detector firstMatchInString:text options:0 range:textRenge];
                    
                    if (!result ||
                        result.range.location > 0 ||
                        result.range.length != text.length ||
                        [result.URL.absoluteString hasPrefix:@"mailto:"]) {
                    }
                    else {
                        
                        [self loadOpenGraphForURL:result.URL.absoluteString ID:ID];
                    }
                });
            }
        }
    }
}

//MARK: - Helpers

- (QMOpenGraphItem *)openGraphWithID:(NSString *)ID
                          dictionary:(NSDictionary *)dictionary
                             baseUrl:(NSString *)baseUrl {
    
    QMOpenGraphItem *openGraphItem = [[QMOpenGraphItem alloc] init];
    
    NSURL *_url = [NSURL URLWithString:baseUrl];
    
    
    openGraphItem.baseUrl = baseUrl;
    openGraphItem.faviconUrl = [NSString stringWithFormat:@"%@://%@/favicon.ico", _url.scheme, _url.host];
    openGraphItem.ID = ID;
    
    if (![dictionary[kQMKeyImageURL] isKindOfClass:[NSNull class]]) {
        
        NSString *imagePath = dictionary[kQMKeyImageURL][@"url"];
        
        if (imagePath != nil) {
            openGraphItem.imageURL = imagePath;
        }
    }
    
    if (![dictionary[kQMKeyTitle] isKindOfClass:[NSNull class]]) {
        
        openGraphItem.siteTitle = dictionary[kQMKeyTitle];
    }
    
    if (![dictionary[kQMKeyDescription] isKindOfClass:[NSNull class]]) {
        
        openGraphItem.siteDescription = dictionary[kQMKeyDescription];
    }
    
    return openGraphItem;
}

- (NSString *)qm_standartitizedURLStringFromString:(NSString *)stringURL {
    
    NSArray *prefixes = @[@"https:", @"http:", @"//", @"/", @"www."];
    
    for (NSString *prefix in prefixes) {
        
        if ([stringURL hasPrefix:prefix]) {
            stringURL =
            [stringURL stringByReplacingOccurrencesOfString:prefix
                                                 withString:@""
                                                    options:NSAnchoredSearch
                                                      range:NSMakeRange(0,stringURL.length)];
        }
    }
    
    return stringURL;
}

@end

@implementation QMOpenGraphLoadOperation

- (void)dealloc {
    
    NSLog(@"%@, class: %@, id: %@", NSStringFromSelector(_cmd), NSStringFromClass(self.class), _identifier);
}

- (NSString *)description {
    
    NSMutableString *result = [NSMutableString stringWithString:[super description]];
    [result appendFormat:@" ->>> %@", _identifier];
    
    return result.copy;
}

@end
