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

@interface QMChatMediaItem : NSObject <NSCopying, NSCoding>

@property (copy, nonatomic) NSString *mediaID;

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSURL *localURL;
@property (copy, nonatomic) NSURL *remoteURL;

@property (nonatomic, assign) NSUInteger mediaDuration;

- (instancetype)initWithName:(NSString *)name
                         localURL:(NSURL *)localURL
                        remoteURL:(NSURL *)remoteURL
                 contentType:(QMMediaContentType)contentType NS_DESIGNATED_INITIALIZER;

+ (instancetype)videoItemWithURL:(NSURL *)itemURL;
+ (instancetype)audioItemWithURL:(NSURL *)itemURL;

- (NSString *)stringMediaType;
- (NSString *)stringMIMEType;

@end
