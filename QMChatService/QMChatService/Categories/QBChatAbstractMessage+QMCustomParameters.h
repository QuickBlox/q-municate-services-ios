//
//  QBChatAbstractMessage+CustomParameters.h
//  Q-municate
//
//  Created by Andrey Ivanov on 24.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Quickblox/Quickblox.h>
#import "QMChatTypes.h"

@interface QBChatAbstractMessage (QM_CustomParameters)

@property (strong, nonatomic) NSString *cParamSaveToHistory;
@property (assign, nonatomic) QMMessageType cParamMessageType;
@property (strong, nonatomic) NSString *cParamChatMessageID;
@property (strong, nonatomic) NSNumber *cParamDateSent;
@property (assign, nonatomic) BOOL cParamMessageDeliveryStatus;

@property (strong, nonatomic) NSString *cParamDialogID;
@property (strong, nonatomic) NSString *cParamRoomJID;
@property (strong, nonatomic) NSString *cParamDialogRoomName;
@property (strong, nonatomic) NSString *cParamDialogRoomPhoto;
@property (strong, nonatomic) NSNumber *cParamDialogType;
@property (strong, nonatomic) NSArray *cParamDialogOccupantsIDs;
@property (strong, nonatomic) NSNumber *cParamDialogDeletedID;

/**
 *  Set custom parameters with chat dialogs

 */
- (void)setCustomParametersWithChatDialog:(QBChatDialog *)chatDialog;

/**
 *  Convert custom parameters to QBChatDialog
 *
 *  @return QBChatDialog instance
 */
- (QBChatDialog *)chatDialogFromCustomParameters;

@end
