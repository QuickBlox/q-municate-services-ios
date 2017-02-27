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

@property (nonatomic, copy) NSString *mediaID;

@property (nonatomic, copy) NSURL *localURL;
@property (nonatomic, copy) NSURL *remoteURL;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) NSData *data;

@property (assign,nonatomic) BOOL isReady;

@property (strong, nonatomic) NSDictionary *metaData;

@property (assign,nonatomic) BOOL isLoaded;
//
@property (assign, nonatomic) Float64 duration;
@property (assign, nonatomic) UIImage *thumbnailImage;//video
//
@property (assign, nonatomic) CGSize videoSize;

@property (assign, nonatomic, readonly) QMMediaContentType contentType;

@property (nonatomic, assign) NSUInteger mediaDuration;
;
@property (copy, nonatomic) void(^onReadyBlock)(void);

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
- (NSString *)extension;



@end
