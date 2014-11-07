#import "CDDialog.h"

@interface CDDialog ()

@end

@implementation CDDialog

- (QBChatDialog *)toQBChatDialog {
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    
    chatDialog.ID = self.id;
    chatDialog.roomJID = self.roomJID;
    chatDialog.type = self.type.intValue;
    chatDialog.name = self.name;
    chatDialog.photo = self.photo;
    chatDialog.lastMessageText = self.lastMessageText;
    chatDialog.lastMessageDate = self.lastMessageDate;
    chatDialog.lastMessageUserID = self.lastMessageUserID.integerValue;
    chatDialog.unreadMessagesCount = self.unreadMessagesCount.integerValue;
    
    NSArray *ids = [self.occupantsIDs componentsSeparatedByString:@","];
    NSMutableArray *occupantsIDS = [NSMutableArray arrayWithCapacity:ids.count];

    for (NSString *occupantID in ids) {
        [occupantsIDS addObject:@(occupantID.integerValue)];
    }
    
    chatDialog.occupantIDs = [occupantsIDS copy];
    
    return chatDialog;
}

- (void)updateWithQBChatDialog:(QBChatDialog *)dialog {

    self.id = dialog.ID;
    self.roomJID = dialog.roomJID;
    self.type = @(dialog.type);
    self.name = dialog.name;
    self.photo = dialog.photo;
    self.lastMessageText = dialog.lastMessageText;
    self.lastMessageDate = dialog.lastMessageDate;
    self.lastMessageUserID = @(dialog.lastMessageUserID);
    self.unreadMessagesCount = @(dialog.unreadMessagesCount);
    
    self.occupantsIDs = [dialog.occupantIDs componentsJoinedByString:@","];
}

@end
