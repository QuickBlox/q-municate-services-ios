// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDDialog.m instead.

#import "_CDDialog.h"

const struct CDDialogAttributes CDDialogAttributes = {
	.dialogOwnerID = @"dialogOwnerID",
	.id = @"id",
	.lastMessageDate = @"lastMessageDate",
	.lastMessageText = @"lastMessageText",
	.lastMessageUserID = @"lastMessageUserID",
	.name = @"name",
	.occupantsIDs = @"occupantsIDs",
	.photo = @"photo",
	.roomJID = @"roomJID",
	.type = @"type",
	.unreadMessagesCount = @"unreadMessagesCount",
};

const struct CDDialogRelationships CDDialogRelationships = {
};

const struct CDDialogFetchedProperties CDDialogFetchedProperties = {
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
	
	if ([key isEqualToString:@"dialogOwnerIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"dialogOwnerID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastMessageUserIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastMessageUserID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"typeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"type"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"unreadMessagesCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unreadMessagesCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic dialogOwnerID;



- (int32_t)dialogOwnerIDValue {
	NSNumber *result = [self dialogOwnerID];
	return [result intValue];
}

- (void)setDialogOwnerIDValue:(int32_t)value_ {
	[self setDialogOwnerID:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDialogOwnerIDValue {
	NSNumber *result = [self primitiveDialogOwnerID];
	return [result intValue];
}

- (void)setPrimitiveDialogOwnerIDValue:(int32_t)value_ {
	[self setPrimitiveDialogOwnerID:[NSNumber numberWithInt:value_]];
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
	[self setLastMessageUserID:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveLastMessageUserIDValue {
	NSNumber *result = [self primitiveLastMessageUserID];
	return [result intValue];
}

- (void)setPrimitiveLastMessageUserIDValue:(int32_t)value_ {
	[self setPrimitiveLastMessageUserID:[NSNumber numberWithInt:value_]];
}





@dynamic name;






@dynamic occupantsIDs;






@dynamic photo;






@dynamic roomJID;






@dynamic type;



- (int16_t)typeValue {
	NSNumber *result = [self type];
	return [result shortValue];
}

- (void)setTypeValue:(int16_t)value_ {
	[self setType:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveTypeValue {
	NSNumber *result = [self primitiveType];
	return [result shortValue];
}

- (void)setPrimitiveTypeValue:(int16_t)value_ {
	[self setPrimitiveType:[NSNumber numberWithShort:value_]];
}





@dynamic unreadMessagesCount;



- (int32_t)unreadMessagesCountValue {
	NSNumber *result = [self unreadMessagesCount];
	return [result intValue];
}

- (void)setUnreadMessagesCountValue:(int32_t)value_ {
	[self setUnreadMessagesCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUnreadMessagesCountValue {
	NSNumber *result = [self primitiveUnreadMessagesCount];
	return [result intValue];
}

- (void)setPrimitiveUnreadMessagesCountValue:(int32_t)value_ {
	[self setPrimitiveUnreadMessagesCount:[NSNumber numberWithInt:value_]];
}










@end
