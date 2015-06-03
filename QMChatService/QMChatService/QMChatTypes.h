//
//  QMChatTypes.h
//  QMChatService
//
//  Created by Andrey Ivanov on 29.04.15.
//
//

typedef NS_ENUM(NSUInteger, QMMessageType) {

    /** Default message type*/
    QMMessageTypeText = 0,
    QMMessageTypeCreateGroupDialog = 1,
    QMMessageTypeUpdateGroupDialog = 2,
    
    QMMessageTypeContactRequest = 4,
    QMMessageTypeAcceptContactRequest,
    QMMessageTypeRejectContactRequest,
    QMMessageTypeDeleteContactRequest
};

