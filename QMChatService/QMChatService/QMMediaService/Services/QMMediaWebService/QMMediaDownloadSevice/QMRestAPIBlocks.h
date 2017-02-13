//
//  QMMediaDownloadBlocks.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

@class QMMediaItem;
@class QBCBlob;

typedef void (^QMMediaRestCompletionBlock)(NSString *mediaID, NSData *data, NSError *error);
typedef void (^QMMediaProgressBlock)(float progress);
typedef void (^QMMediaErrorBlock)(NSError *error);
typedef void (^QMMediaUploadCompletionBlock)(QBCBlob *blob, NSError *error);




