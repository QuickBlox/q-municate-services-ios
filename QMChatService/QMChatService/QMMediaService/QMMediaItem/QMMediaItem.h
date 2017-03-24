//
//  QMChatMediaItem.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 1/23/17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QMMediaContentType) {
    QMMediaContentTypeAudio = 1,
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
                     mediaID:(NSString *)mediaID
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
- (BOOL)isReady;

@end
