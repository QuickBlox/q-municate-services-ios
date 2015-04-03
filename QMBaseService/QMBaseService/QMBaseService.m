//
//  QMBaseService.m
//  Q-municate
//
//  Created by Andrey Ivanov on 04.08.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMBaseService.h"
//#import "REAlertView+QMSuccess.h"

typedef NS_ENUM(NSUInteger, QM_STATUS) {
    QM_STATUS_REGISTER_PUSH_NOTIFICATION,
    QM_STATUS_UN_REGISTER_PUSH_NOTIFICATION
};

@interface QMBaseService()

@property (weak, nonatomic) id <QMUserProfileProtocol> userProfileDataSource;

@end

@implementation QMBaseService

- (instancetype)initWithUserProfileDataSource:(id<QMUserProfileProtocol>)userProfileDataSource{ 
    
    self = [super init];
    if (self) {
        
        self.userProfileDataSource = userProfileDataSource;
        NSLog(@"Init - %@ service...", NSStringFromClass(self.class));
        [self willStart];
    }
    return self;
}

- (void)willStart {
    
}

#pragma mark - error Handler

NSString *const kQBResponceErrorsKey = @"errors";

- (void)showMessageForQBResponce:(QBResponse *)responce {
    
//    [self showMessageForQBError:responce.error status:responce.status];
}

- (void)showMessageForQBError:(QBError *)error status:(NSInteger)status {
    
//    id errors = error.reasons[kQBResponceErrorsKey];
//    NSMutableString *resultErrorMessageString = [NSMutableString string];
//    
//    if ([errors isKindOfClass:[NSDictionary class]]) {
//        
//        for (NSString *key in [errors allKeys]) {
//            NSArray *obj = errors[key];
//            NSString *reason = NSLocalizedString(key, nil);
//            [resultErrorMessageString appendFormat:@"%@ - %@\n", reason, [obj firstObject]];
//        }
//    }
//    else if ([errors isKindOfClass:[NSArray class]]){
//        
//        NSString *errorStr = [errors firstObject];
//        NSString *reason = NSLocalizedString(errorStr, nil);
//        [resultErrorMessageString appendFormat:@"%@\n", reason];
//    }
//    
//    if (resultErrorMessageString.length == 0) {
//        [resultErrorMessageString  appendString:error.error.localizedDescription];
//    }
//    
//    NSString *errorTitle = nil;
//    if (status == 0) {
//        errorTitle = NSLocalizedString(@"QM_STR_ERROR", nil);
//    }
//    else if (status == QBResponseStatusCodeUnknown) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_UNKNOWN", nil);
//    }
//    else if (status == QBResponseStatusCodeValidationFailed) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_VALIDATION_FAILED", nil);
//    }
//    else if (status == QBResponseStatusCodeUnAuthorized) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_UN_AUTORIZED", nil);
//    }
//    else if (status == QBResponseStatusCodeServerError) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_SERVER_ERROR", nil);
//    }
//    else if (status == QBResponseStatusCodeBadRequest) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STAUTS_STR_BAD_REQUEST", nil);
//    }
//    else if (status == QM_STATUS_REGISTER_PUSH_NOTIFICATION) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_UNREGISTER_PUSH_NOTIFICATION", nil);
//    }
//    else if (status == QM_STATUS_UN_REGISTER_PUSH_NOTIFICATION) {
//        errorTitle = NSLocalizedString(@"QM_ERROR_STATUS_STR_REGISTER_PUSH_NOTIFICATION", nil);
//    }
//    
//    [REAlertView showErrorAlertWithTitle:errorTitle message:resultErrorMessageString];
}

- (BOOL)checkResult:(QBResult *)result {
//    
//    if (!result.success) {
//        [REAlertView showAlertWithMessage:result.errors.lastObject actionSuccess:NO];
//    }
//    
//return result.success;
    return YES;
}

@end
