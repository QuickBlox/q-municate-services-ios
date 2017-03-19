// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDAttachment.m instead.

#import "_CDAttachment.h"

@implementation CDAttachmentID
@end

@implementation _CDAttachment

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CDAttachment" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CDAttachment";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CDAttachment" inManagedObjectContext:moc_];
}

- (CDAttachmentID*)objectID {
	return (CDAttachmentID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	if ([key isEqualToString:@"durationValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"duration"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"heightValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"height"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"widthValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"width"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic data;

@dynamic duration;

- (double)durationValue {
	NSNumber *result = [self duration];
	return [result doubleValue];
}

- (void)setDurationValue:(double)value_ {
	[self setDuration:@(value_)];
}

- (double)primitiveDurationValue {
	NSNumber *result = [self primitiveDuration];
	return [result doubleValue];
}

- (void)setPrimitiveDurationValue:(double)value_ {
	[self setPrimitiveDuration:@(value_)];
}

@dynamic height;

- (int64_t)heightValue {
	NSNumber *result = [self height];
	return [result longLongValue];
}

- (void)setHeightValue:(int64_t)value_ {
	[self setHeight:@(value_)];
}

- (int64_t)primitiveHeightValue {
	NSNumber *result = [self primitiveHeight];
	return [result longLongValue];
}

- (void)setPrimitiveHeightValue:(int64_t)value_ {
	[self setPrimitiveHeight:@(value_)];
}

@dynamic id;

@dynamic mimeType;

@dynamic name;

@dynamic url;

@dynamic width;

- (double)widthValue {
	NSNumber *result = [self width];
	return [result doubleValue];
}

- (void)setWidthValue:(double)value_ {
	[self setWidth:@(value_)];
}

- (double)primitiveWidthValue {
	NSNumber *result = [self primitiveWidth];
	return [result doubleValue];
}

- (void)setPrimitiveWidthValue:(double)value_ {
	[self setPrimitiveWidth:@(value_)];
}

@dynamic message;

@end

@implementation CDAttachmentAttributes 
+ (NSString *)data {
	return @"data";
}
+ (NSString *)duration {
	return @"duration";
}
+ (NSString *)height {
	return @"height";
}
+ (NSString *)id {
	return @"id";
}
+ (NSString *)mimeType {
	return @"mimeType";
}
+ (NSString *)name {
	return @"name";
}
+ (NSString *)url {
	return @"url";
}
+ (NSString *)width {
	return @"width";
}
@end

@implementation CDAttachmentRelationships 
+ (NSString *)message {
	return @"message";
}
@end

