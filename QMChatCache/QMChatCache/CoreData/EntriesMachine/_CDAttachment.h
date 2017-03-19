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

@property (atomic) int64_t heightValue;
- (int64_t)heightValue;
- (void)setHeightValue:(int64_t)value_;

@property (nonatomic, strong, nullable) NSString* id;

@property (nonatomic, strong, nullable) NSString* mimeType;

@property (nonatomic, strong, nullable) NSString* name;

@property (nonatomic, strong, nullable) NSString* url;

@property (nonatomic, strong, nullable) NSNumber* width;

@property (atomic) double widthValue;
- (double)widthValue;
- (void)setWidthValue:(double)value_;

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

- (int64_t)primitiveHeightValue;
- (void)setPrimitiveHeightValue:(int64_t)value_;

- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;

- (NSString*)primitiveMimeType;
- (void)setPrimitiveMimeType:(NSString*)value;

- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;

- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;

- (NSNumber*)primitiveWidth;
- (void)setPrimitiveWidth:(NSNumber*)value;

- (double)primitiveWidthValue;
- (void)setPrimitiveWidthValue:(double)value_;

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
+ (NSString *)url;
+ (NSString *)width;
@end

@interface CDAttachmentRelationships: NSObject
+ (NSString *)message;
@end

NS_ASSUME_NONNULL_END
