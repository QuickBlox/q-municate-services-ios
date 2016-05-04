//
//  QMOfflineActionsMemoryStorage.h
//  QMServices
//
//  Created by Vitaliy on 4/29/16.
//
//

#import <Foundation/Foundation.h>
#import "QMMemoryStorageProtocol.h"

@class QBOfflineAction;

@interface QMOfflineActionsMemoryStorage : NSObject  <QMMemoryStorageProtocol>

- (void)addAction:(QBOfflineAction*)offlineAction;

@end
