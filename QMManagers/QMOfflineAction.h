//
//  QMOfflineAction.h
//  QMServices
//
//  Created by Vitaliy on 4/27/16.
//
//

#import <Foundation/Foundation.h>

@class BFTaskCompletionSource;

@interface QMOfflineAction : NSObject

@property (nonatomic,strong) NSDictionary * parameters;

- (instancetype)initWithSource:(BFTaskCompletionSource*)source;

- (void)cancelAction;
- (void)performAction;

@end
