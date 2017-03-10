//
//  QMChatMediaItem.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 1/23/17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QMMediaContentType) {
    QMMediaContentTypeAudio,
    QMMediaContentTypeVideo,
    QMMediaContentTypeImage,
    QMMediaContentTypeCustom
};

@class QBChatAttachment;

@interface QMMediaItem : NSObject <NSCopying, NSCoding>

@property (copy, nonatomic) NSString *mediaID;

@property (copy, nonatomic) NSURL *localURL;
@property (copy, nonatomic) NSURL *remoteURL;

@property (copy, nonatomic) NSString *name;

@property (strong, nonatomic) NSData *data;

@property (copy, nonatomic)  NSString *extension;

@property (assign, nonatomic) NSTimeInterval mediaDuration;
@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) CGSize mediaSize;

@property (assign, nonatomic, readonly) QMMediaContentType contentType;

- (void)updateWithAttachment:(QBChatAttachment *)attachment;

- (instancetype)initWithName:(NSString *)name
                    localURL:(NSURL *)localURL
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType;

+ (instancetype)videoItemWithURL:(NSURL *)itemURL;
+ (instancetype)audioItemWithURL:(NSURL *)itemURL;
+ (instancetype)mediaItemWithImage:(UIImage *)image;
+ (instancetype)mediaItemWithAttachment:(QBChatAttachment *)attachment;

- (NSString *)stringContentType;
- (NSString *)stringMIMEType;

- (NSDictionary *)metaData;

@end
