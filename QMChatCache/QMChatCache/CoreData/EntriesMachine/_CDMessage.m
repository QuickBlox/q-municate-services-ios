// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDMessage.m instead.

#import "_CDMessage.h"

const struct CDMessageAttributes CDMessageAttributes = {
	.customParameters = @"customParameters",
	.datetime = @"datetime",
	.dialogID = @"dialogID",
	.id = @"id",
	.isRead = @"isRead",
	.recipientID = @"recipientID",
	.roomId = @"roomId",
	.senderID = @"senderID",
	.senderNick = @"senderNick",
	.state = @"state",
	.text = @"text",
};

const struct CDMessageRelationships CDMessageRelationships = {
	.attachments = @"attachments",
	.dialog = @"dialog",
};

@implementation CDMessageID
@end

@implementation _CDMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CDMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CDMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CDMessage" inManagedObjectContext:moc_];
}

- (CDMessageID*)objectID {
	return (CDMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"isReadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isRead"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"recipientIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"recipientID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"senderIDValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"senderID"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"stateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"state"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic customParameters;

@dynamic datetime;

@dynamic dialogID;

@dynamic id;

@dynamic isRead;

- (BOOL)isReadValue {
	NSNumber *result = [self isRead];
	return [result boolValue];
}

- (void)setIsReadValue:(BOOL)value_ {
	[self setIsRead:@(value_)];
}

- (BOOL)primitiveIsReadValue {
	NSNumber *result = [self primitiveIsRead];
	return [result boolValue];
}

- (void)setPrimitiveIsReadValue:(BOOL)value_ {
	[self setPrimitiveIsRead:@(value_)];
}

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

@dynamic roomId;

@dynamic senderID;

- (int32_t)senderIDValue {
	NSNumber *result = [self senderID];
	return [result intValue];
}

- (void)setSenderIDValue:(int32_t)value_ {
	[self setSenderID:@(value_)];
}

- (int32_t)primitiveSenderIDValue {
	NSNumber *result = [self primitiveSenderID];
	return [result intValue];
}

- (void)setPrimitiveSenderIDValue:(int32_t)value_ {
	[self setPrimitiveSenderID:@(value_)];
}

@dynamic senderNick;

@dynamic state;

- (int16_t)stateValue {
	NSNumber *result = [self state];
	return [result shortValue];
}

- (void)setStateValue:(int16_t)value_ {
	[self setState:@(value_)];
}

- (int16_t)primitiveStateValue {
	NSNumber *result = [self primitiveState];
	return [result shortValue];
}

- (void)setPrimitiveStateValue:(int16_t)value_ {
	[self setPrimitiveState:@(value_)];
}

@dynamic text;

@dynamic attachments;

- (NSMutableSet*)attachmentsSet {
	[self willAccessValueForKey:@"attachments"];

	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"attachments"];

	[self didAccessValueForKey:@"attachments"];
	return result;
}

@dynamic dialog;

@end

