//
//  QMChatMediaItem.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 1/23/17.
//
//

#import <Foundation/Foundation.h>

#define QM_SERIALIZE_OBJECT(var_name, coder)		[coder encodeObject:var_name forKey:@#var_name]
#define QM_SERIALIZE_INTEGER(var_name, coder)	    [coder encodeInteger:var_name forKey:@#var_name]
#define QM_SERIALIZE_INT(var_name, coder)	        [coder encodeInt:var_name forKey:@#var_name]

#define QM_DESERIALIZE_OBJECT(var_name, decoder)	var_name = [decoder decodeObjectForKey:@#var_name]
#define QM_DESERIALIZE_INTEGER(var_name, decoder)	var_name = [decoder decodeIntegerForKey:@#var_name]
#define QM_DESERIALIZE_INT(var_name, decoder)	    var_name = [decoder decodeIntForKey:@#var_name]


typedef NS_ENUM(NSInteger, QMMediaContentType) {
    QMMediaContentTypeAudio,
    QMMediaContentTypeVideo,
    QMMediaContentTypeImage,
    QMMediaContentTypeCustom
};

@class QBChatAttachment;

@interface QMMediaItem : NSObject <NSCopying>

@property (strong, nonatomic, readonly) QBChatAttachment *attachment;

@property (copy, nonatomic) NSString *mediaID;

@property (copy, nonatomic) NSURL *localURL;
@property (copy, nonatomic) NSURL *remoteURL;

@property (copy, nonatomic) NSString *name;

@property (strong, nonatomic) NSData *data;

@property (assign, nonatomic) NSTimeInterval mediaDuration;
@property (assign, nonatomic) CGSize mediaSize;

@property (strong, nonatomic) UIImage *image;

- (instancetype)initWithName:(NSString *)name
                        data:(NSData *)data
                    localURL:(NSURL *)localURL
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType;


+ (instancetype)videoItemWithFileURL:(NSURL *)itemURL;
+ (instancetype)audioItemWithFileURL:(NSURL *)itemURL;
+ (instancetype)mediaItemWithImage:(UIImage *)image;
+ (instancetype)mediaItemWithAttachment:(QBChatAttachment *)attachment;

@property (copy, nonatomic, readonly)  NSString *extension;
@property (assign, nonatomic, readonly) QMMediaContentType contentType;

- (NSString *)stringContentType;
- (NSString *)stringMIMEType;


@end
