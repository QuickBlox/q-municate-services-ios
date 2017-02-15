//
//  QMMediaBlocks.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

@class QMMediaItem;
@class QBCBlob;
@class QMMediaError;

typedef void (^QMMediaRestCompletionBlock)(NSString *mediaID, NSData *data, QMMediaError *error);
typedef void (^QMMediaProgressBlock)(float progress);
typedef void (^QMMediaErrorBlock)(NSError *error, QBResponseStatusCode);
typedef void (^QMMediaUploadCompletionBlock)(QBCBlob *blob, NSError *error);

typedef void (^QMMediaCompletionBlock)(QMMediaItem *);
typedef void (^QMMessageUploadProgressBlock)(float progress);
typedef void (^QMMessageUploadCompletionBlock)(QMMediaItem *mediaItem, NSError *error);

