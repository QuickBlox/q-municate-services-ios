//
//  QMMediaWebService.h
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 6/14/17.
//

#import <Foundation/Foundation.h>
#import "QMMediaUploadService.h"
#import "QMMediaDownloadService.h"

@protocol QMMediaWebServiceDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface QMMediaWebService : NSObject <QMCancellableService>

@property (weak, nonatomic) id <QMMediaWebServiceDelegate> delegate;

- (BOOL)isDownloadingMessageWithID:(NSString *)messageID;

- (void)downloadMessage:(QBChatMessage *)message
           attachmentID:(NSString *)attachmentID
          progressBlock:(QMAttachmentProgressBlock)progressBlock
        completionBlock:(void(^)(QMDownloadOperation *downloadOperation))completion;

- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                withData:(NSData *)data
           progressBlock:(_Nullable QMAttachmentProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion;


- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
             withFileURL:(NSURL *)fileURL
           progressBlock:(_Nullable QMAttachmentProgressBlock)progressBlock
         completionBlock:(void(^)(QMUploadOperation *downloadOperation))completion;

- (CGFloat)progressForMessageWithID:(NSString *)messageID;

- (void)cancelDownloadOperations;



@end

@protocol QMMediaWebServiceDelegate <NSObject>

@optional

- (BOOL)shouldDownloadAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID;

@end

NS_ASSUME_NONNULL_END
