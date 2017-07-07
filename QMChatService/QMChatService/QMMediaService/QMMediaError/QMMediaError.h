//
//  QMMediaError.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 2/14/17.
//
//

#import <Foundation/Foundation.h>
#import "QMChatTypes.h"

@interface QMMediaError : NSObject

@property (nonatomic, strong, readonly) NSError *error;

#warning ????
@property (nonatomic, assign, readonly) QMMessageAttachmentStatus attachmentStatus;

+ (instancetype)errorWithResponse:(QBResponse *)response;

@end
