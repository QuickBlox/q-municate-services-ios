//
//  QMLinkPreviewManager.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/3/17.
//
//

#import "QMLinkPreviewManager.h"
#import "QMLinkPreviewMemoryStorage.h"
#import "QMLinkPreview.h"

static NSString *const kQMBaseGraphURL = @"https://ogs.quickblox.com/?url=";
static NSString *const kQMKeyTitle = @"ogTitle";
static NSString *const kQMKeyDescription = @"ogDescription";
static NSString *const kQMKeyImageURL = @"ogImage";

@interface QMLinkPreviewManager()

@property (nonatomic, strong) NSMutableSet *previewsInProgress;
@property (nonatomic, strong) NSMutableSet *failedURLs;
@property (nonatomic, strong) NSMutableDictionary *links;
@end

@implementation QMLinkPreviewManager

- (instancetype)init {
    
    if (self = [super init]) {
        _memoryStorage = [[QMLinkPreviewMemoryStorage alloc] init];
        _previewsInProgress = [NSMutableSet set];
        _failedURLs = [NSMutableSet set];
        _links = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)downloadLinkPreviewForMessage:(QBChatMessage *)message
                       withCompletion:(QMLinkPreviewCompletionBlock)completion {
    
    NSURL *url = [self linkForMessage:message];
    
    if (!url) {
        completion(NO);
        return;
    }
    
    [self linkPreviewForURL:url withCompletion:completion];
}


- (void)linkPreviewForURL:(NSURL *)url withCompletion:(QMLinkPreviewCompletionBlock)completion {
    
    NSString *urlKey = [self cacheKeyForURL:url];
    
    if (urlKey.length == 0) {
        
        NSError *error = [[NSError alloc] init];
        completion(NO);
        return;
    }
    
    if ([_failedURLs containsObject:urlKey]) {
        completion(NO);
        return;
    }
    
    if ([_previewsInProgress containsObject:urlKey]) {
        return;
    }
    else {
        
        @synchronized (self.previewsInProgress) {
            [_previewsInProgress addObject:urlKey];
        }
    }
    
    NSString *graphURL = [NSString stringWithFormat:@"%@%@&token=%@",
                          kQMBaseGraphURL,
                          url,
                          [QBSession currentSession].sessionDetails.token];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:graphURL]];
    
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                         
                                         if ([(NSHTTPURLResponse *)response statusCode] == 404) {
                                             
                                             NSError *error = [[NSError alloc] initWithDomain:@"QM_ERROR"
                                                                                         code:404
                                                                                     userInfo:nil];
                                             @synchronized (self.previewsInProgress) {
                                                 [_previewsInProgress removeObject:urlKey];
                                             }
                                             
                                             [_failedURLs addObject:urlKey];
                                             completion(NO);
                                         }
                                         else if (data != nil) {
                                             
                                             NSError *jsonError = nil;
                                             id jsonObject = [NSJSONSerialization
                                                              JSONObjectWithData:data
                                                              options:NSJSONReadingAllowFragments
                                                              error:&jsonError];
                                             
                                             if (jsonObject != nil &&
                                                 jsonError == nil) {
                                                 
                                                 NSLog(@"Successfully deserialized...");
                                                 
                                                 if ([jsonObject isKindOfClass:[NSDictionary class]]){
                                                     
                                                     NSDictionary *deserializedDictionary = (NSDictionary *)jsonObject;
                                                     if (![deserializedDictionary[@"err"] isKindOfClass:[NSNull class]]) {
                                                         
                                                         QMLinkPreview *linkPreview = [[QMLinkPreview alloc] init];
                                                         
                                                         linkPreview.siteUrl = urlKey;
                                                         
                                                         if (![deserializedDictionary[kQMKeyTitle] isKindOfClass:[NSNull class]]) {
                                                             linkPreview.siteTitle = deserializedDictionary[kQMKeyTitle];
                                                         }
                                                         if (![deserializedDictionary[kQMKeyDescription] isKindOfClass:[NSNull class]]) {
                                                             linkPreview.siteDescription = deserializedDictionary[kQMKeyDescription];
                                                         }
                                                         if (![deserializedDictionary[kQMKeyImageURL] isKindOfClass:[NSNull class]]) {
                                                             linkPreview.imageURL = deserializedDictionary[kQMKeyImageURL][@"url"];
                                                         }
                                                         
                                                         [self.memoryStorage addLinkPreview:linkPreview forKey:[self cacheKeyForURL:url]];
                                                         
                                                         if ([self.delegate respondsToSelector:@selector(linkPreviewManager:didAddLinkPreviewToMemoryStorage:)]) {
                                                             [self.delegate linkPreviewManager:self didAddLinkPreviewToMemoryStorage:linkPreview];
                                                         }
                                                         
                                                         @synchronized (self.previewsInProgress) {
                                                             [_previewsInProgress removeObject:urlKey];
                                                         }
                                                         
                                                         if (completion) {
                                                             completion(YES);
                                                         }
                                                     }
                                                     else {
                                                         completion(NO);
                                                     }
                                                     
                                                 }
                                             }
                                         }
                                         else if (error != nil) {
                                             @synchronized (self.previewsInProgress) {
                                                 [_previewsInProgress removeObject:urlKey];
                                             }
                                             completion(NO);
                                         }
                                         
                                     }] resume];
}

- (QMLinkPreview *)linkPreviewForMessage:(QBChatMessage *)message {
    
    NSURL *url = [self linkForMessage:message];
    
    if (!url) {
        return nil;
    }
    NSString *keyURL = [self cacheKeyForURL:url];
    
    if ([_failedURLs containsObject:keyURL]) {
        return nil;
    }
    
    QMLinkPreview *linkPreview = [self.memoryStorage linkPreviewForKey:keyURL];
    
    if (!linkPreview) {
        
        if ([self.delegate respondsToSelector:@selector(cachedLinkPreviewForURLKey:)]) {
            linkPreview = [self.delegate cachedLinkPreviewForURLKey:keyURL];
        }
        
        if (linkPreview != nil) {
            [self.memoryStorage addLinkPreview:linkPreview forKey:keyURL];
        }
    }
    
    return linkPreview;
}



- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (!url) {
        return @"";
    }
    
    return [url absoluteString];
}

- (NSURL *)linkForMessage:(QBChatMessage *)message {
    
    if (_links[message.ID] != nil) {
        return _links[message.ID];
    }
    
    NSURL *url = nil;
    
    NSString *text = message.text;
    
    if (text.length > 0) {
        
        NSError *error = nil;
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                                   error:&error];
        if (error == nil) {
            
            NSTextCheckingResult *result = [detector firstMatchInString:text
                                                                options:0
                                                                  range:NSMakeRange(0, text.length)];
            if (result.resultType == NSTextCheckingTypeLink) {
                url = result.URL;
                _links[message.ID] = url;
            }
        }
    }
    return url;
}

@end
