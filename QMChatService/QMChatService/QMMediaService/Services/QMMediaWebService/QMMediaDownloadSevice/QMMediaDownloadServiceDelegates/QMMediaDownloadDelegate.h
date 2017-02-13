//
//  QMMediaDownloadDelegate.h
//  QMMediaKit
//
//  Created by Vitaliy Gurkovsky on 2/8/17.
//  Copyright © 2017 quickblox. All rights reserved.
//

@protocol QMMediaDownloadDelegate <NSObject>

- (void)didStartDownloadingMediaWithID:(NSString *)mediaID;

- (void)didUpdateDownloadingProgress:(float)progress
                      forMediaWithID:(NSString *)mediaID;

- (void)didEndDownloadingMediaWithID:(NSString *)mediaID
                           mediaData:(NSData *)mediaData
                               error:(NSError *)error;

@end
