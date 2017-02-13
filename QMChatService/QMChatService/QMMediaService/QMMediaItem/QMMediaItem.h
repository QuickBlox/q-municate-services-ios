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
    QMMediaContentTypeCustom
};

@class QBChatAttachment;

@interface QMMediaItem : NSObject <NSCopying, NSCoding>

@property (copy, nonatomic) NSString *mediaID;

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSURL *localURL;
@property (copy, nonatomic) NSURL *remoteURL;
@property (strong, nonatomic) NSData *data;

@property (assign ,nonatomic, readonly) QMMediaContentType contentType;

@property (nonatomic, assign) NSUInteger mediaDuration;

- (void)updateWithAttachment:(QBChatAttachment *)attachment;

- (instancetype)initWithName:(NSString *)name
                         localURL:(NSURL *)localURL
                        remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType;

- (instancetype)initWithName:(NSString *)name
                        data:(NSData *)data
                   remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType;

+ (instancetype)videoItemWithURL:(NSURL *)itemURL;
+ (instancetype)audioItemWithURL:(NSURL *)itemURL;

- (NSString *)stringMediaType;
- (NSString *)stringMIMEType;


@end
