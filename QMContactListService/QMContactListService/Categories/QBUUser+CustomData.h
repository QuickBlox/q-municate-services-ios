//
//  QBUUser+CustomData.h
//  QMContactListService
//
//  Created by Andrey Ivanov on 27.04.15.
//
//

#import <Quickblox/Quickblox.h>

@interface QBUUser (CustomData)

@property (strong, nonatomic) NSString *avatarUrl;
@property (strong, nonatomic) NSString *status;
@property (assign, nonatomic) BOOL isImport;

@end
