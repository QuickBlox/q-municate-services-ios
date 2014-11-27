#import "_CDContactListItem.h"

@interface CDContactListItem : _CDContactListItem {}

- (QBContactListItem *)toQBContactListItem;
- (void)updateWithQBContactListItem:(QBContactListItem *)contactListItem;
- (BOOL)isEqualQBContactListItem:(QBContactListItem *)other;

@end
