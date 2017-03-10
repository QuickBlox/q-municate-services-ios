//
//  QMChatMediaItem.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 1/23/17.
//


#define QM_SERIALIZE_OBJECT(var_name, coder)		[coder encodeObject:var_name forKey:@#var_name]
#define QM_SERIALIZE_INTEGER(var_name, coder)	    [coder encodeInteger:var_name forKey:@#var_name]
#define QM_SERIALIZE_INT(var_name, coder)	        [coder encodeInt:var_name forKey:@#var_name]

#define QM_DESERIALIZE_OBJECT(var_name, decoder)	var_name = [decoder decodeObjectForKey:@#var_name]
#define QM_DESERIALIZE_INTEGER(var_name, decoder)	var_name = [decoder decodeIntegerForKey:@#var_name]
#define QM_DESERIALIZE_INT(var_name, decoder)	    var_name = [decoder decodeIntForKey:@#var_name]

#import "QBChatAttachment+QMCustomData.h"
#import "QMMediaItem.h"

@interface QMMediaItem()

@property (assign, nonatomic) QMMediaContentType contentType;

@end

@implementation QMMediaItem
@dynamic extension;

//MARK: Class methods
+ (instancetype)mediaItemWithAttachment:(QBChatAttachment *)attachment {
    QMMediaItem *item = [[QMMediaItem alloc] init];
    [item updateWithAttachment:attachment];
    return item;
}
+ (instancetype)mediaItemWithImage:(UIImage *)image {
    
    QMMediaItem *item = [[QMMediaItem alloc] initWithName:@"image" localURL:nil remoteURL:nil contentType:QMMediaContentTypeImage];
    item.image = image;
    return item;
}

+ (instancetype)videoItemWithURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"video" localURL:itemURL remoteURL:nil contentType:QMMediaContentTypeVideo];
}

+ (instancetype)audioItemWithURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"audio" localURL:itemURL remoteURL:nil contentType:QMMediaContentTypeAudio];
}

- (void)updateWithAttachment:(QBChatAttachment *)attachment {
    
    self.mediaID = attachment.ID;
    if (attachment.url.length) {
        self.remoteURL = [self remoteURLWithString:attachment.url];
    }
    
    if ([attachment.type isEqualToString:@"audio"]) {
        self.contentType = QMMediaContentTypeAudio;
    }
    else if ([attachment.type isEqualToString:@"video"]) {
        
        self.contentType = QMMediaContentTypeVideo;
    }
    else if ([attachment.type isEqualToString:@"image"]) {
        self.contentType = QMMediaContentTypeImage;
    }
    
    NSDictionary *size = attachment.context[@"size"];
    
    if (size) {
        
        CGFloat width = [size[@"width"] doubleValue];
        CGFloat height = [size[@"height"] doubleValue];
        self.mediaSize = CGSizeMake(width, height);
    }
    if (attachment.context[@"duration"]) {
        self.mediaDuration = [attachment.context[@"duration"] doubleValue];
    }
    
}
- (NSURL *)remoteURL {
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:_remoteURL
                                             resolvingAgainstBaseURL:false];
    
    components.query = [NSString stringWithFormat:@"token=%@",[QBSession currentSession].sessionDetails.token];
    return components.URL;
}
//MARK: Initialize
- (instancetype)initWithName:(NSString *)name
                    localURL:(NSURL *)localURL
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType {
    
    if (self = [super init]) {
        
        _name = [name copy];
        _localURL = [localURL copy];
        _remoteURL = [remoteURL copy];
        _contentType = contentType;
    }
    
    return self;
}

- (instancetype)initWithName:(NSString *)name
                        data:(NSData *)data
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType {
    
    if (self = [super init]) {
        
        _name = [name copy];
        _remoteURL = [remoteURL copy];
        _data = [data copy];
        _contentType = contentType;
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
            stringMediaType = @"mp3";
            break;
            
        case QMMediaContentTypeVideo:
            stringMediaType = @"mp4";
            break;
            
        case QMMediaContentTypeImage:
        default:
            stringMediaType = @"png";
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

//MARK: - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    
    QMMediaItem *copy = [[[self class] allocWithZone:zone] init];
    
    copy.mediaID  = [self.mediaID copyWithZone:zone];
    copy.localURL = [self.localURL copyWithZone:zone];
    copy.remoteURL = [self.localURL copyWithZone:zone];
    copy.name  = [self.name copyWithZone:zone];
    copy.contentType = self.contentType;
    copy.mediaDuration = self.mediaDuration;
    if (_thumbnailImage) {
        copy.thumbnailImage = [[UIImage allocWithZone: zone] initWithCGImage: (__bridge CGImageRef _Nonnull)(self.thumbnailImage.CIImage)];
    }
    return copy;
}

//MARK: - NSCoding

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
        
        QM_DESERIALIZE_OBJECT(_mediaID, aDecoder);
        QM_DESERIALIZE_OBJECT(_localURL, aDecoder);
        QM_DESERIALIZE_OBJECT(_remoteURL, aDecoder);
        QM_DESERIALIZE_OBJECT(_name, aDecoder);
        QM_DESERIALIZE_INT(_contentType, aDecoder);
        QM_DESERIALIZE_INTEGER(_mediaDuration, aDecoder);
    }
    
    return self;
}
#pragma clang diagnostic pop

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    QM_SERIALIZE_OBJECT(_mediaID, aCoder);
    QM_SERIALIZE_OBJECT(_localURL, aCoder);
    QM_SERIALIZE_OBJECT(_remoteURL, aCoder);
    QM_SERIALIZE_OBJECT(_name, aCoder);
    QM_SERIALIZE_INT(_contentType, aCoder);
    QM_SERIALIZE_INTEGER(_mediaDuration, aCoder);
}


- (NSDictionary *)metaData {
    
    NSMutableDictionary *metaData = [NSMutableDictionary new];
    
    if  (self.contentType == QMMediaContentTypeAudio || self.contentType == QMMediaContentTypeVideo) {
        
        if (self.mediaDuration > 0) {
            metaData[@"duration"] = @(self.mediaDuration);
        }
    }
    if ((self.contentType == QMMediaContentTypeVideo
         || self.contentType == QMMediaContentTypeImage) && !CGSizeEqualToSize(self.mediaSize, CGSizeZero)) {
        
        metaData[@"width"] = @(self.mediaSize.width);
        metaData[@"height" ] = @(self.mediaSize.height);
    }
    
    return metaData.allKeys.count ? metaData.copy : nil;
}

- (NSURL *)remoteURLWithString:(NSString *)stringURL {
    
    NSURLComponents *components = [NSURLComponents componentsWithString:stringURL];
    components.queryItems = nil;
    return components.URL;
}




@end
