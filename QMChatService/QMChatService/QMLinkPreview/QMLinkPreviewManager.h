//
//  QMLinkPreviewManager.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/3/17.
//
//

@class QMLinkPreview;
@class QMLinkPreviewMemoryStorage;

@protocol QMLinkPreviewManagerDelegate;

typedef void(^QMLinkPreviewCompletionBlock)(BOOL sucess);
typedef QMLinkPreview *(^QMCacheBlock)(NSString *keyURL);

NS_ASSUME_NONNULL_BEGIN

@interface QMLinkPreviewManager : NSObject

@property (nonatomic, copy) QMCacheBlock cacheBlock;
@property (nonatomic, strong) QMLinkPreviewMemoryStorage *memoryStorage;
@property (nonatomic, weak) id <QMLinkPreviewManagerDelegate> delegate;

- (void)downloadLinkPreviewForMessage:(QBChatMessage *)message
                       withCompletion:(QMLinkPreviewCompletionBlock)completion;

- (QMLinkPreview *)linkPreviewForMessage:(QBChatMessage *)message;

@end

@protocol QMLinkPreviewManagerDelegate <NSObject>

- (void)linkPreviewManager:(QMLinkPreviewManager *)linkPreview didAddLinkPreviewToMemoryStorage:(QMLinkPreview *)linkPreview;
- (QMLinkPreview *)cachedLinkPreviewForURLKey:(NSString *)urlKey;

@end
NS_ASSUME_NONNULL_END
