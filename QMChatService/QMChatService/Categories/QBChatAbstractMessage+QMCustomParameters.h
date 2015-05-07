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
 *  This method is used to determine if the message data item contains text or media.
 *  If this method returns `YES`, an instance of `QMChatViewController` will ignore
 *  the `text` method of this protocol when dequeuing a `QMChatCollectionViewCell`
 *  and only call the `media` method.
 *
 *  Similarly, if this method returns `NO` then the `media` method will be ignored and
 *  and only the `text` method will be called.
 *
 *  @return A boolean value specifying whether or not this is a media message or a text message.
 *  Return `YES` if this item is a media message, and `NO` if it is a text message.
 */
- (BOOL)isMediaMessage;
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
