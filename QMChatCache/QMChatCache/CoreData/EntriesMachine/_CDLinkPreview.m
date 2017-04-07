// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDLinkPreview.m instead.

#import "_CDLinkPreview.h"

@implementation CDLinkPreviewID
@end

@implementation _CDLinkPreview

+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"CDLinkPreview" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"CDLinkPreview";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"CDLinkPreview" inManagedObjectContext:moc_];
}

- (CDLinkPreviewID*)objectID {
	return (CDLinkPreviewID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

	return keyPaths;
}

@dynamic imageURL;

@dynamic siteDescription;

@dynamic title;

@dynamic url;

@end

@implementation CDLinkPreviewAttributes 
+ (NSString *)imageURL {
	return @"imageURL";
}
+ (NSString *)siteDescription {
	return @"siteDescription";
}
+ (NSString *)title {
	return @"title";
}
+ (NSString *)url {
	return @"url";
}
@end

