// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDDialog.h instead.

#import <CoreData/CoreData.h>


extern const struct CDDialogAttributes {
	__unsafe_unretained NSString *createdAt;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *lastMessageDate;
	__unsafe_unretained NSString *lastMessageText;
	__unsafe_unretained NSString *lastMessageUserID;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *occupantsIDs;
	__unsafe_unretained NSString *photo;
	__unsafe_unretained NSString *recipientID;
	__unsafe_unretained NSString *roomJID;
	__unsafe_unretained NSString *type;
	__unsafe_unretained NSString *unreadMessagesCount;
	__unsafe_unretained NSString *userID;
} CDDialogAttributes;

extern const struct CDDialogRelationships {
	__unsafe_unretained NSString *messages;
} CDDialogRelationships;

extern const struct CDDialogFetchedProperties {
} CDDialogFetchedProperties;

@class CDMessage;







@class NSObject;







@interface CDDialogID : NSManagedObjectID {}
@end

@interface _CDDialog : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CDDialogID*)objectID;





@property (nonatomic, strong) NSDate* createdAt;



//- (BOOL)validateCreatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* id;



//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastMessageDate;



//- (BOOL)validateLastMessageDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* lastMessageText;



//- (BOOL)validateLastMessageText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* lastMessageUserID;



@property int32_t lastMessageUserIDValue;
- (int32_t)lastMessageUserIDValue;
- (void)setLastMessageUserIDValue:(int32_t)value_;

//- (BOOL)validateLastMessageUserID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id occupantsIDs;



//- (BOOL)validateOccupantsIDs:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* photo;



//- (BOOL)validatePhoto:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* recipientID;



@property int32_t recipientIDValue;
- (int32_t)recipientIDValue;
- (void)setRecipientIDValue:(int32_t)value_;

//- (BOOL)validateRecipientID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* roomJID;



//- (BOOL)validateRoomJID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* type;



@property int16_t typeValue;
- (int16_t)typeValue;
- (void)setTypeValue:(int16_t)value_;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* unreadMessagesCount;



@property int32_t unreadMessagesCountValue;
- (int32_t)unreadMessagesCountValue;
- (void)setUnreadMessagesCountValue:(int32_t)value_;

//- (BOOL)validateUnreadMessagesCount:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* userID;



@property int32_t userIDValue;
- (int32_t)userIDValue;
- (void)setUserIDValue:(int32_t)value_;

//- (BOOL)validateUserID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *messages;

- (NSMutableSet*)messagesSet;





@end

@interface _CDDialog (CoreDataGeneratedAccessors)

- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(CDMessage*)value_;
- (void)removeMessagesObject:(CDMessage*)value_;

@end

@interface _CDDialog (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveCreatedAt;
- (void)setPrimitiveCreatedAt:(NSDate*)value;




- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;




- (NSDate*)primitiveLastMessageDate;
- (void)setPrimitiveLastMessageDate:(NSDate*)value;




- (NSString*)primitiveLastMessageText;
- (void)setPrimitiveLastMessageText:(NSString*)value;




- (NSNumber*)primitiveLastMessageUserID;
- (void)setPrimitiveLastMessageUserID:(NSNumber*)value;

- (int32_t)primitiveLastMessageUserIDValue;
- (void)setPrimitiveLastMessageUserIDValue:(int32_t)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (id)primitiveOccupantsIDs;
- (void)setPrimitiveOccupantsIDs:(id)value;




- (NSString*)primitivePhoto;
- (void)setPrimitivePhoto:(NSString*)value;




- (NSNumber*)primitiveRecipientID;
- (void)setPrimitiveRecipientID:(NSNumber*)value;

- (int32_t)primitiveRecipientIDValue;
- (void)setPrimitiveRecipientIDValue:(int32_t)value_;




- (NSString*)primitiveRoomJID;
- (void)setPrimitiveRoomJID:(NSString*)value;




- (NSNumber*)primitiveType;
- (void)setPrimitiveType:(NSNumber*)value;

- (int16_t)primitiveTypeValue;
- (void)setPrimitiveTypeValue:(int16_t)value_;




- (NSNumber*)primitiveUnreadMessagesCount;
- (void)setPrimitiveUnreadMessagesCount:(NSNumber*)value;

- (int32_t)primitiveUnreadMessagesCountValue;
- (void)setPrimitiveUnreadMessagesCountValue:(int32_t)value_;




- (NSNumber*)primitiveUserID;
- (void)setPrimitiveUserID:(NSNumber*)value;

- (int32_t)primitiveUserIDValue;
- (void)setPrimitiveUserIDValue:(int32_t)value_;





- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;


@end
