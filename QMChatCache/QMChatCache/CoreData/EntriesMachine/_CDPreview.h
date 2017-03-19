// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDPreview.h instead.

#if __has_feature(modules)
    @import Foundation;
    @import CoreData;
#else
    #import <Foundation/Foundation.h>
    #import <CoreData/CoreData.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CDPreviewID : NSManagedObjectID {}
@end

@interface _CDPreview : NSManagedObject
+ (instancetype)insertInManagedObjectContext:(NSManagedObjectContext *)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) CDPreviewID *objectID;

@end

@interface _CDPreview (CoreDataGeneratedPrimitiveAccessors)

@end

NS_ASSUME_NONNULL_END
