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
//MARK: Class methods

+ (instancetype)videoItemWithURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"video" localURL:itemURL remoteURL:nil contentType:QMMediaContentTypeVideo];
}

+ (instancetype)audioItemWithURL:(NSURL *)itemURL {
    
    return [[QMMediaItem alloc] initWithName:@"audio" localURL:itemURL remoteURL:nil contentType:QMMediaContentTypeAudio];
}

- (void)updateWithAttachment:(QBChatAttachment *)attachment {
    
    self.mediaID = attachment.ID;
    self.remoteURL = [NSURL URLWithString:attachment.url];
    
    if ([attachment.type isEqualToString:@"audio"]) {
        
        self.contentType = QMMediaContentTypeAudio;
        
        CGFloat duration = [attachment.context[@"duration"] floatValue];
        if (duration > 0) {
            self.duration = duration;
        }
    }
    
    else if ([attachment.type isEqualToString:@"video"]) {
        
        self.contentType = QMMediaContentTypeVideo;
        
        NSDictionary *size = attachment.context[@"size"];
        
        if (size) {
            
            CGFloat width = [size[@"width"] doubleValue];
            CGFloat height = [size[@"height"] doubleValue];
            self.videoSize = CGSizeMake(width, height);
        }
    }
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
    
    return [NSString stringWithFormat:@"<%@: %p; name = %@; localURL = %@; remote = %@; mediaType = %@; mimeType = %@; duration = %f>",
            NSStringFromClass([self class]),
            self,
            self.name,
            self.localURL,
            self.remoteURL,
            [self stringContentType],
            [self stringMIMEType],
            self.duration
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

- (void)setIsReady:(BOOL)isReady {
    
    if (_isReady != isReady) {
        
        _isReady = isReady;
        
        if (isReady &&_onReadyBlock){
            _onReadyBlock();
        }
    }
}


- (NSDictionary *)metaData {
    
    NSMutableDictionary *metaData = [NSMutableDictionary new];
    
    if  (self.contentType == QMMediaContentTypeAudio || self.contentType == QMMediaContentTypeVideo) {
        
        if (self.duration > 0) {
            metaData[@"duration"] = @(self.duration);
        }
        
        if (self.contentType == QMMediaContentTypeVideo && !CGSizeEqualToSize(self.videoSize, CGSizeZero)) {
            
            metaData[@"width"] = @(self.videoSize.width);
            metaData[@"height" ] = @(self.videoSize.height);
        }
    }
    
    return metaData.allKeys.count ? metaData.copy : nil;
}

@end
