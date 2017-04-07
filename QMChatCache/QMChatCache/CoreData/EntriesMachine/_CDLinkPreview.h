// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDLinkPreview.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CDLinkPreviewID : NSManagedObjectID {}
@end

@interface _CDLinkPreview : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CDLinkPreviewID *objectID;

@property (nonatomic, strong, nullable) NSString* imageURL;

@property (nonatomic, strong, nullable) NSString* siteDescription;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSString* url;

@end

@interface _CDLinkPreview (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveImageURL;
- (void)setPrimitiveImageURL:(NSString*)value;

- (NSString*)primitiveSiteDescription;
- (void)setPrimitiveSiteDescription:(NSString*)value;

- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;

- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;

@end

@interface CDLinkPreviewAttributes: NSObject 
+ (NSString *)imageURL;
+ (NSString *)siteDescription;
+ (NSString *)title;
+ (NSString *)url;
@end

NS_ASSUME_NONNULL_END
