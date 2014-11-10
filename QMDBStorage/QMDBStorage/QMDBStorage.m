//
//  QMDBStorage.m
//  QMDBStorage
//
//  Created by Andrey on 06.11.14.
//
//

#import "QMDBStorage.h"

@interface QMDBStorage ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSString *storeName;

@end

@implementation QMDBStorage

static QMDBStorage *_storage = nil;

NSString *StoreFileName(NSString *name) {
    
    NSString* fileName = [NSString stringWithFormat:@"%@.sqlite", name];
    return fileName;
}

+ (void)setupDBWithName:(NSString *)name {
    
    if (_storage) {
        NSAssert(nil, @"Need clean old storage before setup new");
    }
    _storage = nil;
    
    [QMMagicalRecord cleanUp];
    
//    MagicalRecordStack *stack = [MagicalRecord setupAutoMigratingStackWithSQLiteStoreNamed:StoreFileName(name)];
//    _storage = [[QMDBStorage alloc] initWithStack:stack storeName:name];
    
//    NSManagedObjectModel * model = [NSManagedObjectModel MR_newModelNamed:<#(NSString *)#> inBundle:<#(NSBundle *)#>
}

+ (QMDBStorage *)shared {
    
    NSAssert(_storage, @"You must first perform @selector(setupWithName:)");
    return _storage;
}

+ (NSURL *)storeUrlWithName:(NSString *)name {
    
//    NSURL *storeUrl = nil[NSPersistentStore MR_fileURLForStoreNameIfExistsOnDisk:StoreFileName(name)];
    return nil;
}

+ (void)cleanDBWithName:(NSString *)name {
    
    [QMMagicalRecord cleanUp];
    
    NSURL *storeUrl = [self storeUrlWithName:name];
    
    if (storeUrl) {
        
        NSError *error = nil;
        if(![[NSFileManager defaultManager] removeItemAtURL:storeUrl error:&error]) {
            NSLog(@"An error has occurred while deleting %@", storeUrl);
            NSLog(@"Error description: %@", error.description);
        }
        else {
            NSLog(@"Clear %@ - Done!", storeUrl);
        }
    }
}

//- (instancetype)initWithStack:(MagicalRecordStack *)stack storeName:(NSString *)storeName {
//    
//    self = [super init];
//    
//    if (self) {
//        
//        self.queue = dispatch_queue_create("com.qmunicate.DBQueue", NULL);
////        self.stack = stack;
//        self.storeName = storeName;
//    }
//    
//    return self;
//}

- (NSManagedObjectContext *)context {
    
    if (!_context) {
//        _context = [NSManagedObjectContext MR_confinementContextWithParent:self.stack.context];
    }
    
    return _context;
}

- (void)async:(void(^)(NSManagedObjectContext *context))block {
    
    dispatch_async(self.queue, ^{
        block(self.context);
    });
}

- (void)sync:(void(^)(NSManagedObjectContext *context))block {
    
    dispatch_sync(self.queue, ^{
        block(self.context);
    });
}

- (void)save:(void(^)(void))completion {
    
    [self async:^(NSManagedObjectContext *context) {
        
        [context QM_saveToPersistentStoreAndWait];
        if(completion)
            DO_AT_MAIN(completion());
    }];
}

@end
