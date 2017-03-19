// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDPreview.m instead.

#import "_CDPreview.h"

@implementation CDPreviewID
@end

@implementation _CDPreview

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CDPreview" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CDPreview";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CDPreview" inManagedObjectContext:moc_];
}

- (CDPreviewID*)objectID {
	return (CDPreviewID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@end

