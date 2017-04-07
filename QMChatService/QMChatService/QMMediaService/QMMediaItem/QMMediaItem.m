//
//  QMChatMediaItem.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 1/23/17.
//


#import "QBChatAttachment+QMCustomData.h"
#import "QMMediaItem.h"

@interface QMMediaItem()

@property (assign, nonatomic) QMMediaContentType contentType;
@property (strong, nonatomic) QBChatAttachment *attachment;

@end

@implementation QMMediaItem
@synthesize attachment = _attachment;
@synthesize remoteURL = _remoteURL;
@dynamic extension;


//MARK: Class methods

+ (instancetype)mediaItemWithAttachment:(QBChatAttachment *)attachment {
    
    NSString *name = attachment.name;
    NSString *mediaID = attachment.ID;
    QMMediaContentType contentType;
    
    if ([attachment.type isEqualToString:@"audio"]) {
        contentType = QMMediaContentTypeAudio;
    }
    else if ([attachment.type isEqualToString:@"video"]) {
        
        contentType = QMMediaContentTypeVideo;
    }
    else if ([attachment.type isEqualToString:@"image"]) {
        contentType = QMMediaContentTypeImage;
    }
    
    QMMediaItem *item = [[QMMediaItem alloc] initWithName:name
                                                  mediaID:mediaID
                                                     data:nil
                                                 localURL:nil
                                                remoteURL:nil
                                              contentType:contentType];
    item.attachment = attachment;

    
    
    return item;
}

- (void)updateWithAttachment:(QBChatAttachment *)attachment {
    
//    _name = attachment.name;
//    _mediaID = attachment.ID;
//    
//    QMMediaContentType contentType;
//    
//    if ([attachment.type isEqualToString:@"audio"]) {
//        contentType = QMMediaContentTypeAudio;
//    }
//    else if ([attachment.type isEqualToString:@"video"]) {
//        
//        contentType = QMMediaContentTypeVideo;
//    }
//    else if ([attachment.type isEqualToString:@"image"]) {
//        contentType = QMMediaContentTypeImage;
//    }
//    
//    _contentType = contentType;
//    
//    CGSize size = CGSizeMake(attachment.width, attachment.height);
//    
//    if (!CGSizeEqualToSize(size, CGSizeZero)) {
//        _mediaSize = size;
//    }
//    
//    _mediaDuration = attachment.duration;
}



+ (instancetype)mediaItemWithImage:(UIImage *)image {
    
    QMMediaItem *item = [[QMMediaItem alloc] initWithName:@"Image attachment"
                                                  mediaID:nil
                                                     data:nil
                                                 localURL:nil
                                                remoteURL:nil
                                              contentType:QMMediaContentTypeImage];
    item.image = image;
    
    return item;
}

+ (instancetype)videoItemWithFileURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"Video attachment"
                                     mediaID:nil
                                        data:nil
                                    localURL:itemURL
                                   remoteURL:nil
                                 contentType:QMMediaContentTypeVideo];
}

+ (instancetype)audioItemWithFileURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"Voice message"
                                     mediaID:nil
                                        data:nil
                                    localURL:itemURL
                                   remoteURL:nil
                                 contentType:QMMediaContentTypeAudio];
}


- (void)setMediaID:(NSString *)mediaID {
    _mediaID = mediaID;
    self.attachment.ID = mediaID;
}

- (void)setAttachment:(QBChatAttachment *)attachment {
    
    if (_attachment) {
        return;
    }
    _attachment = attachment;
    
    [self updateWithAttachment:attachment];
}


- (NSString *)nameForContentType:(QMMediaContentType)contentType {
    
    NSString *stringMIMEType = nil;
    
    switch (self.contentType) {
        case QMMediaContentTypeAudio:
            stringMIMEType = @"audio/caf";
            break;
            
        case QMMediaContentTypeVideo:
            stringMIMEType = @"video/mp4";
            break;
            
        case QMMediaContentTypeImage:
            stringMIMEType = @"image/png";
            break;
            
        default:
            stringMIMEType = @"";
            break;
    }
    
    return stringMIMEType;
    
}

- (NSURL *)remoteURL {
    
    if (_mediaID.length == 0) {
        return nil;
    }
    
    NSString *apiEndpoint = [QBSettings apiEndpoint];
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:apiEndpoint]
                                             resolvingAgainstBaseURL:false];
    components.path = [NSString stringWithFormat:@"/blobs/%@", _mediaID];
    components.query = [NSString stringWithFormat:@"token=%@",[QBSession currentSession].sessionDetails.token];
    
    _remoteURL = components.URL;
    
    return components.URL;
}

//MARK: Initialize
- (instancetype)initWithName:(NSString *)name
                     mediaID:(NSString *)mediaID
                        data:(NSData *)data
                    localURL:(NSURL *)localURL
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType {
    
    if (self = [super init]) {
        _name = [name copy];
        _mediaID = [mediaID copy];
        _localURL = [localURL copy];
        _remoteURL = [remoteURL copy];
        _contentType = contentType;
        _data = data;
    }
    
    return self;
}



- (NSString *)stringMIMEType {
    
    NSString *stringMIMEType = nil;
    
    switch (self.contentType) {
        case QMMediaContentTypeAudio:
            stringMIMEType = @"audio/caf";
            break;
            
        case QMMediaContentTypeVideo:
            stringMIMEType = @"video/mp4";
            break;
            
        case QMMediaContentTypeImage:
            stringMIMEType = @"image/png";
            break;
            
        default:
            stringMIMEType = @"";
            break;
    }
    
    return stringMIMEType;
}

- (NSString *)stringContentType {
    
    NSString *stringContentType = nil;
    
    switch (self.contentType) {
        case QMMediaContentTypeAudio:
            stringContentType = @"audio";
            break;
            
        case QMMediaContentTypeVideo:
            stringContentType = @"video";
            break;
            
        case QMMediaContentTypeImage:
            stringContentType = @"image";
            break;
        default:
            stringContentType = @"";
            break;
    }
    
    return stringContentType;
}

- (NSString *)extension {
    
    NSString *stringMediaType = nil;
    
    switch (self.contentType) {
        case QMMediaContentTypeAudio:
            stringMediaType = @"m4a";
            break;
            
        case QMMediaContentTypeVideo:
            stringMediaType = @"mp4";
            break;
            
        case QMMediaContentTypeImage:
            stringMediaType = @"png";
            break;
            
        default:
            stringMediaType = @"";
            break;
    }
    
    return stringMediaType;
}

//MARK: - NSObject

- (BOOL)isEqual:(id)object {
    
    if (self == object) {
        
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        
        return NO;
    }
    
    QMMediaItem *mediaItem = (QMMediaItem *)object;
    
    if (_mediaID != nil ? ![_mediaID isEqualToString:mediaItem.mediaID] : mediaItem.mediaID != nil) {
        
        return NO;
    }
    
    return [super isEqual:object];
}

- (NSString *)description {
    
    return [NSString stringWithFormat:@"<%@: %p; name = %@; localURL = %@; remoteURL = %@; mediaType = %@; mimeType = %@; duration = %f> ; size = %@",
            NSStringFromClass([self class]),
            self,
            self.name,
            self.localURL,
            self.remoteURL,
            [self stringContentType],
            [self stringMIMEType],
            self.mediaDuration,
            NSStringFromCGSize(self.mediaSize)
            ];
}

- (NSUInteger)hash {
    
    return [self.localURL hash];
}



- (BOOL)isReady {
    if (self.contentType == QMMediaContentTypeImage) {
        return YES;
    }
   else  if (self.contentType == QMMediaContentTypeAudio) {
        return self.mediaDuration > 0;
    }
    else if (self.contentType == QMMediaContentTypeVideo) {
        return self.mediaDuration > 0 && self.image != nil;
    }
    
    return YES;
}

@end
