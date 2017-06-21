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
+ (nullable NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CDLinkPreviewID *objectID;

@property (nonatomic, strong, nullable) NSNumber* height;

@property (atomic) int16_t heightValue;
- (int16_t)heightValue;
- (void)setHeightValue:(int16_t)value_;

@property (nonatomic, strong, nullable) NSString* identifier;

@property (nonatomic, strong, nullable) NSString* imageURL;

@property (nonatomic, strong, nullable) NSString* siteDescription;

@property (nonatomic, strong, nullable) NSString* title;

@property (nonatomic, strong, nullable) NSString* url;

@property (nonatomic, strong, nullable) NSNumber* width;

@property (atomic) int16_t widthValue;
- (int16_t)widthValue;
- (void)setWidthValue:(int16_t)value_;

@end

@interface _CDLinkPreview (CoreDataGeneratedPrimitiveAccessors)

- (nullable NSNumber*)primitiveHeight;
- (void)setPrimitiveHeight:(nullable NSNumber*)value;

- (int16_t)primitiveHeightValue;
- (void)setPrimitiveHeightValue:(int16_t)value_;

- (nullable NSString*)primitiveIdentifier;
- (void)setPrimitiveIdentifier:(nullable NSString*)value;

- (nullable NSString*)primitiveImageURL;
- (void)setPrimitiveImageURL:(nullable NSString*)value;

- (nullable NSString*)primitiveSiteDescription;
- (void)setPrimitiveSiteDescription:(nullable NSString*)value;

- (nullable NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(nullable NSString*)value;

- (nullable NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(nullable NSString*)value;

- (nullable NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(nullable NSNumber*)value;

- (int16_t)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(int16_t)value_;

@end

@interface CDLinkPreviewAttributes: NSObject 
+ (NSString *)height;
+ (NSString *)identifier;
+ (NSString *)imageURL;
+ (NSString *)siteDescription;
+ (NSString *)title;
+ (NSString *)url;
+ (NSString *)width;
@end

NS_ASSUME_NONNULL_END
