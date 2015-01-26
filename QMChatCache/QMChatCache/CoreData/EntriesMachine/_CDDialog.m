// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDDialog.m instead.

#import "_CDDialog.h"

const struct CDDialogAttributes CDDialogAttributes = {
	.createdAt = @"createdAt",
	.dialogType = @"dialogType",
	.id = @"id",
	.lastMessageDate = @"lastMessageDate",
	.lastMessageText = @"lastMessageText",
	.lastMessageUserID = @"lastMessageUserID",
	.name = @"name",
	.occupantsIDs = @"occupantsIDs",
	.photo = @"photo",
	.recipientID = @"recipientID",
	.roomJID = @"roomJID",
	.unreadMessagesCount = @"unreadMessagesCount",
	.userID = @"userID",
};

const struct CDDialogRelationships CDDialogRelationships = {
	.messages = @"messages",
};

@implementation CDDialogID
@end

@implementation _CDDialog

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CDDialog" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CDDialog";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CDDialog" inManagedObjectContext:moc_];
}

- (CDDialogID*)objectID {
	return (CDDialogID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"dialogTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"dialogType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastMessageUserIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastMessageUserID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"recipientIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"recipientID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadMessagesCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unreadMessagesCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"userIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"userID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic createdAt;

@dynamic dialogType;

- (int16_t)dialogTypeValue {
	NSNumber *result = [self dialogType];
	return [result shortValue];
}

- (void)setDialogTypeValue:(int16_t)value_ {
	[self setDialogType:@(value_)];
}

- (int16_t)primitiveDialogTypeValue {
	NSNumber *result = [self primitiveDialogType];
	return [result shortValue];
}

- (void)setPrimitiveDialogTypeValue:(int16_t)value_ {
	[self setPrimitiveDialogType:@(value_)];
}

@dynamic id;

@dynamic lastMessageDate;

@dynamic lastMessageText;

@dynamic lastMessageUserID;

- (int32_t)lastMessageUserIDValue {
	NSNumber *result = [self lastMessageUserID];
	return [result intValue];
}

- (void)setLastMessageUserIDValue:(int32_t)value_ {
	[self setLastMessageUserID:@(value_)];
}

- (int32_t)primitiveLastMessageUserIDValue {
	NSNumber *result = [self primitiveLastMessageUserID];
	return [result intValue];
}

- (void)setPrimitiveLastMessageUserIDValue:(int32_t)value_ {
	[self setPrimitiveLastMessageUserID:@(value_)];
}

@dynamic name;

@dynamic occupantsIDs;

@dynamic photo;

@dynamic recipientID;

- (int32_t)recipientIDValue {
	NSNumber *result = [self recipientID];
	return [result intValue];
}

- (void)setRecipientIDValue:(int32_t)value_ {
	[self setRecipientID:@(value_)];
}

- (int32_t)primitiveRecipientIDValue {
	NSNumber *result = [self primitiveRecipientID];
	return [result intValue];
}

- (void)setPrimitiveRecipientIDValue:(int32_t)value_ {
	[self setPrimitiveRecipientID:@(value_)];
}

@dynamic roomJID;

@dynamic unreadMessagesCount;

- (int32_t)unreadMessagesCountValue {
	NSNumber *result = [self unreadMessagesCount];
	return [result intValue];
}

- (void)setUnreadMessagesCountValue:(int32_t)value_ {
	[self setUnreadMessagesCount:@(value_)];
}

- (int32_t)primitiveUnreadMessagesCountValue {
	NSNumber *result = [self primitiveUnreadMessagesCount];
	return [result intValue];
}

- (void)setPrimitiveUnreadMessagesCountValue:(int32_t)value_ {
	[self setPrimitiveUnreadMessagesCount:@(value_)];
}

@dynamic userID;

- (int32_t)userIDValue {
	NSNumber *result = [self userID];
	return [result intValue];
}

- (void)setUserIDValue:(int32_t)value_ {
	[self setUserID:@(value_)];
}

- (int32_t)primitiveUserIDValue {
	NSNumber *result = [self primitiveUserID];
	return [result intValue];
}

- (void)setPrimitiveUserIDValue:(int32_t)value_ {
	[self setPrimitiveUserID:@(value_)];
}

@dynamic messages;

- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];

	[self didAccessValueForKey:@"messages"];
	return result;
}

@end

