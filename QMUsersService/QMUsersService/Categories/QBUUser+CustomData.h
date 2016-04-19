//
//  QBUUser+CustomData.h
//  QMServices
//
//  Created by Andrey Ivanov on 27.04.15.
//  Copyright (c) 2015 Quickblox Team. All rights reserved.
//

#import <Quickblox/Quickblox.h>

@interface QBUUser (CustomData)

@property (strong, nonatomic, QB_NULLABLE) NSString *avatarUrl;
@property (strong, nonatomic, QB_NULLABLE) NSString *status;
@property (assign, nonatomic) BOOL isImport;

@end
