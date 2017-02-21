#import "CDContactListItem.h"

@implementation CDContactListItem

- (QBContactListItem *)toQBContactListItem {
    
    QBContactListItem *contactListItem = [[QBContactListItem alloc] init];
    contactListItem.userID = self.userID.integerValue;
    contactListItem.subscriptionState = self.subscriptionState.intValue;
    contactListItem.online = NO;
    
    return contactListItem;
}

- (void)updateWithQBContactListItem:(QBContactListItem *)contactListItem {
    
    if (self.subscriptionStateValue != contactListItem.subscriptionState) {
        self.subscriptionStateValue = contactListItem.subscriptionState;
    }
    
    if (self.userIDValue != contactListItem.userID) {
        self.userIDValue = contactListItem.userID;
    }
}

@end
