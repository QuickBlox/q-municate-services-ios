//
//  QBChatAbstractMessage+CustomParameters.m
//  Q-municate
//
//  Created by Andrey Ivanov on 24.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QBChatAbstractMessage+QMCustomParameters.h"

/*Message keys*/
NSString const *kQMCustomParameterSaveToHistory = @"save_to_history";
NSString const *kQMCustomParameterMessageType = @"notification_type";
NSString const *kQMCustomParameterChatMessageID = @"chat_message_id";
NSString const *kQMCustomParameterDateSent = @"date_sent";
NSString const *kQMCustomParameterChatMessageDeliveryStatus = @"message_delivery_status_read";
/*Dialogs keys*/
NSString const *kQMCustomParameterDialogID = @"dialog_id";
NSString const *kQMCustomParameterRoomJID = @"room_jid";
NSString const *kQMCustomParameterDialogRoomName = @"room_name";
NSString const *kQMCustomParameterDialogRoomPhoto = @"room_photo";
NSString const *kQMCustomParameterDialogType = @"type";
NSString const *kQMCustomParameterDialogOccupantsIDs = @"occupants_ids";
NSString const *kQMCustomParameterDialogDeletedID = @"deleted_id";

@interface QBChatAbstractMessage (Context)

@property (strong, nonatomic) NSMutableDictionary *context;

@end

@implementation QBChatAbstractMessage (QMCustomParameters)

/*Message params*/
@dynamic saveToHistory;
@dynamic messageType;
@dynamic chatMessageID;
@dynamic dateSent;
@dynamic messageDeliveryStatus;

/*dialog info params*/
@dynamic dialogID;
@dynamic roomJID;
@dynamic roomName;
@dynamic dialogType;
@dynamic dialogOccupantsIDs;
@dynamic roomPhoto;
@dynamic dialogDeletedID;

- (NSMutableDictionary *)context {
    
    if (!self.customParameters) {
        self.customParameters = [NSMutableDictionary dictionary];
    }
    
    return self.customParameters;
}

#pragma mark - cParamChatMessageID

- (void)setChatMessageID:(NSString *)chatMessageID {
    
    self.context[kQMCustomParameterChatMessageID] = chatMessageID;
}

- (NSString *)chatMessageID {
    
    return self.context[kQMCustomParameterChatMessageID];
}

#pragma mark - dateSent

- (void)setDateSent:(NSNumber *)dateSent {
    
    self.context[kQMCustomParameterDateSent] = dateSent;
}

- (NSNumber *)dateSent {
    
    return self.context[kQMCustomParameterDateSent];
}

#pragma mark - dialogID

- (void)setDialogID:(NSString *)dialogID {
    
    self.context[kQMCustomParameterDialogID] = dialogID;
}

- (NSString *)dialogID {
    
    return self.context[kQMCustomParameterDialogID];
}

#pragma mark - cParamSaveToHistory

- (void)setSaveToHistory:(NSString *)saveToHistory {
    
    self.context[kQMCustomParameterSaveToHistory] = saveToHistory;
}

- (NSString *)saveToHistory {
    
    return self.context[kQMCustomParameterSaveToHistory];
}

#pragma mark - roomJID

- (void)setRoomJID:(NSString *)roomJID {
    
    self.context[kQMCustomParameterRoomJID] = roomJID;
}

- (NSString *)roomJID {
    
    return self.context[kQMCustomParameterRoomJID];
}

#pragma mark - dialogType

- (void)setDialogType:(NSNumber *)dialogType {
    
    self.context[kQMCustomParameterDialogType] = dialogType;
}

- (NSNumber *)dialogType {
    
    return self.context[kQMCustomParameterDialogType];
}

#pragma mark - roomName

- (void)setRoomName:(NSString *)roomName {
    
    self.context[kQMCustomParameterDialogRoomName] = roomName;
}

- (NSString *)roomName {
    
    return self.context[kQMCustomParameterDialogRoomName];
}

#pragma mark - roomPhoto

- (void)setRoomPhoto:(NSString *)roomPhoto {
    
    self.context[kQMCustomParameterDialogRoomPhoto] = roomPhoto;
}

- (NSString *)roomPhoto
{
    return self.context[kQMCustomParameterDialogRoomPhoto];
}

#pragma mark - dialogDeletedID

- (void)setDialogDeletedID:(NSNumber *)dialogDeletedID {
    
    self.context[kQMCustomParameterDialogDeletedID] = dialogDeletedID;
}

-(NSNumber *)dialogDeletedID {
    
    return self.context[kQMCustomParameterDialogDeletedID];
}

#pragma mark - dialogOccupantsIDs

- (void)setDialogOccupantsIDs:(NSArray *)dialogOccupantsIDs {
    
    NSString *strIDs = [dialogOccupantsIDs componentsJoinedByString:@","];
    self.context[kQMCustomParameterDialogOccupantsIDs] = strIDs;
}

- (NSArray *)dialogOccupantsIDs {
    
    NSString * strIDs = self.context[kQMCustomParameterDialogOccupantsIDs];
    
    NSArray *componets = [strIDs componentsSeparatedByString:@","];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:componets.count];
    
    for (NSString *occupantID in componets) {
        
        [result addObject:@(occupantID.integerValue)];
    }
    
    return result;
}

#pragma mark - messageType

- (void)setMessageType:(QMMessageType)messageType {
    
    self.context[kQMCustomParameterMessageType] = @(messageType);
}

- (QMMessageType)messageType {
    
    return [self.context[kQMCustomParameterMessageType] integerValue];
}

- (BOOL)isNotificatonMessage {
    
    return self.messageType != QMMessageTypeText;
}

#pragma mark - messageDeliveryStatus

- (void)setMessageDeliveryStatus:(BOOL)messageDeliveryStatus {
    
    self.context[kQMCustomParameterChatMessageDeliveryStatus] = @(messageDeliveryStatus);
}

- (BOOL)messageDeliveryStatus {
    
    return [self.context[kQMCustomParameterChatMessageDeliveryStatus] boolValue];
}

#pragma mark - QBChatDialog

- (void)setCustomParametersWithChatDialog:(QBChatDialog *)chatDialog {
    
    self.dialogID = chatDialog.ID;
    
    if (chatDialog.type == QBChatDialogTypeGroup) {
        self.roomJID = chatDialog.roomJID;
        self.roomName = chatDialog.name;
    }
    
    self.dialogType = @(chatDialog.type);
    self.dialogOccupantsIDs = chatDialog.occupantIDs;
}

- (QBChatDialog *)chatDialogFromCustomParameters {
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    
    chatDialog.ID = self.dialogID;
    chatDialog.roomJID = self.roomJID;
    chatDialog.name = self.roomName;
    chatDialog.occupantIDs = self.dialogOccupantsIDs;
    chatDialog.type = self.dialogType.intValue;
    chatDialog.photo = self.roomPhoto;
    
    return chatDialog;
}

- (BOOL)isMediaMessage {
   return self.attachments.count > 0;
}

@end
