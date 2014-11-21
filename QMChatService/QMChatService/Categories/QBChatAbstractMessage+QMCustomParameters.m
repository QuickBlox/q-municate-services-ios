//
//  QBChatAbstractMessage+CustomParameters.m
//  Qmunicate
//
//  Created by Andrey Ivanov on 24.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//
#import "QBChatAbstractMessage+QMCustomParameters.h"

/*Message keys*/
NSString const *kQMCustomParameterSaveToHistoryKey = @"save_to_history";
NSString const *kQMCustomParameterNotificationTypeKey = @"notification_type";
NSString const *kQMCustomParameterChatMessageIDKey = @"chat_message_id";
NSString const *kQMCustomParameterDateSentKey = @"date_sent";
NSString const *kQMCustomParameterChatMessageDeliveryStatusKey = @"message_delivery_status_read";
/*Dialogs keys*/
NSString const *kQMCustomParameterDialogIDKey = @"dialog_id";
NSString const *kQMCustomParameterRoomJIDKey = @"room_jid";
NSString const *kQMCustomParameterDialogNameKey = @"name";
NSString const *kQMCustomParameterDialogTypeKey = @"type";
NSString const *kQMCustomParameterDialogOccupantsIDsKey = @"occupants_ids";

@interface QBChatAbstractMessage (Context)

@property (strong, nonatomic) NSMutableDictionary *context;

@end

@implementation QBChatAbstractMessage (QM_CustomParameters)

/*Message params*/
@dynamic cParamSaveToHistory;
@dynamic cParamNotificationType;
@dynamic cParamChatMessageID;
@dynamic cParamDateSent;
@dynamic cParamMessageDeliveryStatus;

/*dialog info params*/
@dynamic cParamDialogID;
@dynamic cParamRoomJID;
@dynamic cParamDialogName;
@dynamic cParamDialogType;
@dynamic cParamDialogOccupantsIDs;

- (NSMutableDictionary *)context {
    
    if (!self.customParameters) {
        self.customParameters = [NSMutableDictionary dictionary];
    }
    return self.customParameters;
}

#pragma mark - cParamChatMessageID

- (void)setCParamChatMessageID:(NSString *)cParamChatMessageID {
    self.context[kQMCustomParameterChatMessageIDKey] = cParamChatMessageID;
}

- (NSString *)cParamChatMessageID {
    
    return self.context[kQMCustomParameterChatMessageIDKey];
}

#pragma mark - cParamDateSent

- (void)setCParamDateSent:(NSNumber *)cParamDateSent {
    self.context[kQMCustomParameterDateSentKey] = cParamDateSent;
}

- (NSNumber *)cParamDateSent {
    return self.context[kQMCustomParameterDateSentKey];
}

#pragma mark - cParamDialogID

- (void)setCParamDialogID:(NSString *)cParamDialogID {
    self.context[kQMCustomParameterDialogIDKey] = cParamDialogID;
}

- (NSString *)cParamDialogID {
    return self.context[kQMCustomParameterDialogIDKey];
}

#pragma mark - cParamSaveToHistory

- (void)setCParamSaveToHistory:(NSString *)cParamSaveToHistory {
    self.context[kQMCustomParameterSaveToHistoryKey] = cParamSaveToHistory;
}

- (NSString *)cParamSaveToHistory {
    return self.context[kQMCustomParameterSaveToHistoryKey];
}

#pragma mark - cParamRoomJID

- (void)setCParamRoomJID:(NSString *)cParamRoomJID {
    self.context[kQMCustomParameterRoomJIDKey] = cParamRoomJID;
}

- (NSString *)cParamRoomJID {
    return self.context[kQMCustomParameterRoomJIDKey];
}

#pragma mark - cParamDialogType

- (void)setCParamDialogType:(NSNumber *)cParamDialogType {
    self.context[kQMCustomParameterDialogTypeKey] = cParamDialogType;
}

- (NSNumber *)cParamDialogType {
    return self.context[kQMCustomParameterDialogTypeKey];
}

#pragma mark - cParamDialogName

- (void)setCParamDialogName:(NSString *)cParamDialogName {
    self.context[kQMCustomParameterDialogNameKey] = cParamDialogName;
}

- (NSString *)cParamDialogName {
    return self.context[kQMCustomParameterDialogNameKey];
}

#pragma mark - cParamDialogOccupantsIDs

- (void)setCParamDialogOccupantsIDs:(NSArray *)cParamDialogOccupantsIDs {
    
    NSString *strIDs = [cParamDialogOccupantsIDs componentsJoinedByString:@","];
    self.context[kQMCustomParameterDialogOccupantsIDsKey] = strIDs;
}

- (NSArray *)cParamDialogOccupantsIDs {
    
    NSString * strIDs = self.context[kQMCustomParameterDialogOccupantsIDsKey];
    
    NSArray *componets = [strIDs componentsSeparatedByString:@","];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:componets.count];
    
    for (NSString *occupantID in componets) {
        [result addObject:@(occupantID.integerValue)];
    }
    
    return result;
}

#pragma mark - cParamNotificationType

- (void)setCParamNotificationType:(QMMessageNotificationType)cParamNotificationType {
    
    self.context[kQMCustomParameterNotificationTypeKey] = @(cParamNotificationType);
}

- (QMMessageNotificationType)cParamNotificationType {
    return [self.context[kQMCustomParameterNotificationTypeKey] integerValue];
}

#pragma mark - cParamMessageDeliveryStatus

- (void)setCParamMessageDeliveryStatus:(BOOL)cParamMessageDeliveryStatus {
    self.context[kQMCustomParameterChatMessageDeliveryStatusKey] = @(cParamMessageDeliveryStatus);
}

- (BOOL)cParamMessageDeliveryStatus {
    return [self.context[kQMCustomParameterChatMessageDeliveryStatusKey] boolValue];
}

#pragma mark - QBChatDialog

- (void)setCustomParametersWithChatDialog:(QBChatDialog *)chatDialog {
    
    self.cParamDialogID = chatDialog.ID;
    
    if (chatDialog.type == QBChatDialogTypeGroup) {
        self.cParamRoomJID = chatDialog.roomJID;
        self.cParamDialogName = chatDialog.name;
    }
    
    self.cParamDialogType = @(chatDialog.type);
    self.cParamDialogOccupantsIDs = chatDialog.occupantIDs;
}

- (QBChatDialog *)chatDialogFromCustomParameters {
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    chatDialog.ID = self.cParamDialogID;
    chatDialog.roomJID = self.cParamRoomJID;
    chatDialog.name = self.cParamDialogName;
    chatDialog.occupantIDs = self.cParamDialogOccupantsIDs;
    chatDialog.type = self.cParamDialogType.intValue;
    chatDialog.lastMessageDate = [NSDate dateWithTimeIntervalSince1970:self.cParamDateSent.doubleValue];
    chatDialog.lastMessageText = self.text;
    chatDialog.unreadMessagesCount++;
    chatDialog.lastMessageUserID = self.senderID;
    
    return chatDialog;
}

@end
