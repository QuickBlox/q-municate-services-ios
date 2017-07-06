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

- (void)downloadDataForAttachment:(QBChatAttachment *)attachment
                        messageID:(NSString *)messageID
              withCompletionBlock:(QMAttachmentDataCompletionBlock)completionBlock
                    progressBlock:(QMMediaProgressBlock)progressBlock
                     cancellBlock:(QMAttachmentDownloadCancellBlock)cancellBlock;

- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
                withData:(NSData *)data
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock;

- (void)uploadAttachment:(QBChatAttachment *)attachment
               messageID:(NSString *)messageID
             withFileURL:(NSURL *)fileURL
     withCompletionBlock:(QMAttachmentUploadCompletionBlock)completionBlock
           progressBlock:(QMMediaProgressBlock)progressBlock;

- (CGFloat)progressForMessageWithID:(NSString *)messageID;



@end

@protocol QMMediaWebServiceDelegate <NSObject>

@optional

- (BOOL)shouldDownloadAttachment:(QBChatAttachment *)attachment messageID:(NSString *)messageID;

@end

NS_ASSUME_NONNULL_END
