#import "_CDContactListItem.h"

@interface CDContactListItem : _CDContactListItem {}

- (QBContactListItem *)toQBContactListItem;
- (void)updateWithQBContactListItem:(QBContactListItem *)contactListItem;
- (BOOL)isEqual:(QBContactListItem *)other;

@end
