//
//  QMOfflineAction.h
//  QMServices
//
//  Created by Vitaliy on 4/27/16.
//
//

#import <Foundation/Foundation.h>

@class BFTaskCompletionSource;

typedef NS_ENUM(NSUInteger, QMOfflineActionType) {
    QMOfflineActionTypeNone      = 0,
    QMOfflineActionTypeMessage     = 1,
    QMOfflineActionTypeCreateDialog      = 2,
    QMDialogUpdateTypeAddingOccupants = 3
};

@interface QMOfflineAction : NSObject

@property (nonatomic,strong) NSDictionary * parameters;
@property (nonatomic,assign) QMOfflineActionType actionType;

- (instancetype)initWithSource:(BFTaskCompletionSource*)source;

- (void)cancelAction;
- (void)performAction;

@end


