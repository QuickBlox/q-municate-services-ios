// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDAttachment.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class CDMessage;

@interface CDAttachmentID : NSManagedObjectID {}
@end

@interface _CDAttachment : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CDAttachmentID *objectID;

@property (nonatomic, strong, nullable) NSString* data;

@property (nonatomic, strong, nullable) NSNumber* duration;

@property (atomic) double durationValue;
- (double)durationValue;
- (void)setDurationValue:(double)value_;

@property (nonatomic, strong, nullable) NSNumber* height;

@property (atomic) int32_t heightValue;
- (int32_t)heightValue;
- (void)setHeightValue:(int32_t)value_;

@property (nonatomic, strong, nullable) NSString* id;

@property (nonatomic, strong, nullable) NSString* mimeType;

@property (nonatomic, strong, nullable) NSString* name;

@property (nonatomic, strong, nullable) NSNumber* size;

@property (atomic) int64_t sizeValue;
- (int64_t)sizeValue;
- (void)setSizeValue:(int64_t)value_;

@property (nonatomic, strong, nullable) NSString* url;

@property (nonatomic, strong, nullable) NSNumber* width;

@property (atomic) int32_t widthValue;
- (int32_t)widthValue;
- (void)setWidthValue:(int32_t)value_;

@property (nonatomic, strong, nullable) CDMessage *message;

@end

@interface _CDAttachment (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveData;
- (void)setPrimitiveData:(NSString*)value;

- (NSNumber*)primitiveDuration;
- (void)setPrimitiveDuration:(NSNumber*)value;

- (double)primitiveDurationValue;
- (void)setPrimitiveDurationValue:(double)value_;

- (NSNumber*)primitiveHeight;
- (void)setPrimitiveHeight:(NSNumber*)value;

- (int32_t)primitiveHeightValue;
- (void)setPrimitiveHeightValue:(int32_t)value_;

- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;

- (NSString*)primitiveMimeType;
- (void)setPrimitiveMimeType:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSNumber*)primitiveSize;
- (void)setPrimitiveSize:(NSNumber*)value;

- (int64_t)primitiveSizeValue;
- (void)setPrimitiveSizeValue:(int64_t)value_;

- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;

- (NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(NSNumber*)value;

- (int32_t)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(int32_t)value_;

- (CDMessage*)primitiveMessage;
- (void)setPrimitiveMessage:(CDMessage*)value;

@end

@interface CDAttachmentAttributes: NSObject 
+ (NSString *)data;
+ (NSString *)duration;
+ (NSString *)height;
+ (NSString *)id;
+ (NSString *)mimeType;
+ (NSString *)name;
+ (NSString *)size;
+ (NSString *)url;
+ (NSString *)width;
@end

@interface CDAttachmentRelationships: NSObject
+ (NSString *)message;
@end

NS_ASSUME_NONNULL_END
