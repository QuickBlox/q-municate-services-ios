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
    
    self.userID = @(contactListItem.userID);
    self.subscriptionState = @(contactListItem.subscriptionState);
}

@end
