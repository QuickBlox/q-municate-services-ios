//
//  QBChatAbstractMessage+CustomParameters.h
//  Q-municate
//
//  Created by Andrey Ivanov on 24.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <Quickblox/Quickblox.h>
#import "QMChatTypes.h"

@interface QBChatAbstractMessage (QMCustomParameters)

/**
 *  Message
 */
@property (strong, nonatomic) NSString *saveToHistory;
@property (assign, nonatomic) QMMessageType messageType;
@property (strong, nonatomic) NSString *chatMessageID;
@property (strong, nonatomic) NSNumber *dateSent;
@property (assign, nonatomic) BOOL messageDeliveryStatus;

/**
 *  Dialog
 */
@property (strong, nonatomic) NSString *dialogID;
@property (strong, nonatomic) NSString *roomJID;
@property (strong, nonatomic) NSString *roomName;
@property (strong, nonatomic) NSString *roomPhoto;
@property (strong, nonatomic) NSNumber *dialogType;
@property (strong, nonatomic) NSArray *dialogOccupantsIDs;
@property (strong, nonatomic) NSNumber *dialogDeletedID;

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
