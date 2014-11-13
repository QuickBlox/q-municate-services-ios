// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CDMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct CDMessageAttributes {
	__unsafe_unretained NSString *customParameters;
	__unsafe_unretained NSString *datetime;
	__unsafe_unretained NSString *dialogID;
	__unsafe_unretained NSString *id;
	__unsafe_unretained NSString *isRead;
	__unsafe_unretained NSString *recipientID;
	__unsafe_unretained NSString *roomId;
	__unsafe_unretained NSString *senderID;
	__unsafe_unretained NSString *senderNick;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *text;
} CDMessageAttributes;

extern const struct CDMessageRelationships {
	__unsafe_unretained NSString *attachments;
	__unsafe_unretained NSString *dialog;
} CDMessageRelationships;

extern const struct CDMessageFetchedProperties {
} CDMessageFetchedProperties;

@class CDAttachment;
@class CDDialog;













@interface CDMessageID : NSManagedObjectID {}
@end

@interface _CDMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CDMessageID*)objectID;





@property (nonatomic, strong) NSData* customParameters;



//- (BOOL)validateCustomParameters:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* datetime;



//- (BOOL)validateDatetime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* dialogID;



//- (BOOL)validateDialogID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* id;



//- (BOOL)validateId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isRead;



@property BOOL isReadValue;
- (BOOL)isReadValue;
- (void)setIsReadValue:(BOOL)value_;

//- (BOOL)validateIsRead:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* recipientID;



@property int32_t recipientIDValue;
- (int32_t)recipientIDValue;
- (void)setRecipientIDValue:(int32_t)value_;

//- (BOOL)validateRecipientID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* roomId;



//- (BOOL)validateRoomId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* senderID;



@property int32_t senderIDValue;
- (int32_t)senderIDValue;
- (void)setSenderIDValue:(int32_t)value_;

//- (BOOL)validateSenderID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* senderNick;



//- (BOOL)validateSenderNick:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* state;



@property int16_t stateValue;
- (int16_t)stateValue;
- (void)setStateValue:(int16_t)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* text;



//- (BOOL)validateText:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *attachments;

- (NSMutableSet*)attachmentsSet;




@property (nonatomic, strong) CDDialog *dialog;

//- (BOOL)validateDialog:(id*)value_ error:(NSError**)error_;





@end

@interface _CDMessage (CoreDataGeneratedAccessors)

- (void)addAttachments:(NSSet*)value_;
- (void)removeAttachments:(NSSet*)value_;
- (void)addAttachmentsObject:(CDAttachment*)value_;
- (void)removeAttachmentsObject:(CDAttachment*)value_;

@end

@interface _CDMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveCustomParameters;
- (void)setPrimitiveCustomParameters:(NSData*)value;




- (NSDate*)primitiveDatetime;
- (void)setPrimitiveDatetime:(NSDate*)value;




- (NSString*)primitiveDialogID;
- (void)setPrimitiveDialogID:(NSString*)value;




- (NSString*)primitiveId;
- (void)setPrimitiveId:(NSString*)value;




- (NSNumber*)primitiveIsRead;
- (void)setPrimitiveIsRead:(NSNumber*)value;

- (BOOL)primitiveIsReadValue;
- (void)setPrimitiveIsReadValue:(BOOL)value_;




- (NSNumber*)primitiveRecipientID;
- (void)setPrimitiveRecipientID:(NSNumber*)value;

- (int32_t)primitiveRecipientIDValue;
- (void)setPrimitiveRecipientIDValue:(int32_t)value_;




- (NSString*)primitiveRoomId;
- (void)setPrimitiveRoomId:(NSString*)value;




- (NSNumber*)primitiveSenderID;
- (void)setPrimitiveSenderID:(NSNumber*)value;

- (int32_t)primitiveSenderIDValue;
- (void)setPrimitiveSenderIDValue:(int32_t)value_;




- (NSString*)primitiveSenderNick;
- (void)setPrimitiveSenderNick:(NSString*)value;




- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (int16_t)primitiveStateValue;
- (void)setPrimitiveStateValue:(int16_t)value_;




- (NSString*)primitiveText;
- (void)setPrimitiveText:(NSString*)value;





- (NSMutableSet*)primitiveAttachments;
- (void)setPrimitiveAttachments:(NSMutableSet*)value;



- (CDDialog*)primitiveDialog;
- (void)setPrimitiveDialog:(CDDialog*)value;


@end
