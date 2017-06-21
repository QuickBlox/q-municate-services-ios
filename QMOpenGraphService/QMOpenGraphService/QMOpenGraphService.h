//
//  QMOpenGraphService.h
//  QMOpenGraphService
//
//  Created by Andrey Ivanov on 14/06/2017.
//  Copyright © 2017 QuickBlox. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QMMemoryStorageProtocol.h"
#import "QMOpenGraphMemoryStorage.h"
#import "QMOpenGraphItem.h"

@protocol QMOpenGraphServiceDelegate;
@protocol QMOpenGraphCacheDataSource;

NS_ASSUME_NONNULL_BEGIN

@interface QMOpenGraphService : NSObject

/**
 Memory storage for QMLinkPreview
 */
@property (nonatomic, readonly) QMOpenGraphMemoryStorage *memoryStorage;

- (instancetype)initWithCacheDataSource:(id<QMOpenGraphCacheDataSource>)cacheDataSource NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/**
 *  Add instance that confirms Open Graph service multicaste protocol.
 *
 *  @param delegate instance that confirms id<QMOpenGraphServiceDelegate> protocol
 */
- (void)addDelegate:(id <QMOpenGraphServiceDelegate>)delegate;

/**
 *  Remove instance that confirms Open Graph service multicaste protocol.
 *
 *  @param delegate instance that confirms id<QMOpenGraphServiceDelegate> protocol
 */
- (void)removeDelegate:(id <QMOpenGraphServiceDelegate>)delegate;

/**
 Method returns cached instance of QMOpenGraphItem class
 
 @param ID Identifier
 */
- (void)openGraphItemForText:(NSString *)text ID:(NSString *)ID;

@end

@protocol QMOpenGraphServiceDelegate <NSObject>

/**
 Called if ..
 
 @param openGraphSerivce Open graph serivce
 @param openGraphItem QMOpenGraphItem instance
 */
- (void)openGraphSerivce:(QMOpenGraphService *)openGraphSerivce
didAddOpenGraphItemToMemoryStorage:(QMOpenGraphItem *)openGraphItem;

- (void)openGraphSerivce:(QMOpenGraphService *)openGraphSerivce
          didLoadFavicon:(UIImage *)fiveIcon
                  forURL:(NSURL *)url;

- (void)openGraphSerivce:(QMOpenGraphService *)openGraphSerivce
     didLoadPreviewImage:(UIImage *)previewImage
                  forURL:(NSURL *)url;

- (void)openGraphSerivce:(QMOpenGraphService *)openGraphSerivce
        didLoadFromCache:(QMOpenGraphItem *)openGraph;
@end

@protocol QMOpenGraphCacheDataSource <NSObject>

- (nullable QMOpenGraphItem *)cachedOpenGraphItemWithID:(NSString *)ID URLString:(NSString *)URLString;

@end

NS_ASSUME_NONNULL_END
