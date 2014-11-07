#import "_CDContactListItem.h"

@interface CDContactListItem : _CDContactListItem {}

- (QBContactListItem *)toQBContactListItem;
- (void)updateWithQBContactListItem:(QBContactListItem *)contactListItem;

@end
