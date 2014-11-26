//
//  QMBaseService.h
//  Q-municate
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QMServiceDataDelegate <NSObject>
@required
- (QBUUser *)serviceDataCurrentProfile;
@end

@interface QMBaseService : NSObject

@property (weak, nonatomic, readonly) id <QMServiceDataDelegate> serviceDataDelegate;

- (id)init __attribute__((unavailable("init is not a supported initializer for this class.")));
- (id)initWithServiceDataDelegate:(id<QMServiceDataDelegate>)serviceDataDelegate;
- (void)showMessageForQBResponce:(QBResponse *)responce;

@end
