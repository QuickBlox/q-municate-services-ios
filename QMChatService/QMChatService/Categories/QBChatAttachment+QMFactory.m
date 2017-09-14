//
//  QBChatAttachment+QMFactory.m
//  QMChatService
//
//  Created by Vitaliy Gurkovsky on 3/26/17.
//
//

#import "QBChatAttachment+QMFactory.h"

@implementation QBChatAttachment (QMFactory)

+ (instancetype)initWithName:(nullable NSString *)name
                     fileURL:(nullable NSURL *)fileURL
                 contentType:(NSString *)contentType
              attachmentType:(QMAttachmentType)contentType {
    
    QBChatAttachment *attachment = [QBChatAttachment new];
    
    attachment.name = name;
    attachment.localFileURL = localURL;
    attachment.attachmentType = attachmentType;
    attachment.contentType = contentType;
    attachment.type = [attachment stringContentType];
    
    return attachment;
}

+ (instancetype)videoAttachmentWithFileURL:(NSURL *)fileURL {
    
    NSParameterAssert(fileURL);
    
    return [self initWithName:@"Video attachment"
                     fileURL:fileURL
                  contentType:@"video/mp4"
               attachmentType:QMAttachmentContentTypeVideo];
}

+ (instancetype)audioAttachmentWithFileURL:(NSURL *)fileURL {
    
    NSParameterAssert(fileURL);
    
    return [self initWithName:@"Voice message"
                     fileURL:fileURL
                  contentType:@"audio/m4a"
               attachmentType:QMAttachmentContentTypeAudio];
}

+ (instancetype)imageAttachmentWithImage:(UIImage *)image {
    
    NSParameterAssert(image);
    
    int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    
    NSString *contentType = [NSString stringWithFormat:@"image/%@", hasAlpha ? @"png" : @"jpeg"];
    
    QBChatAttachment *attachment = [self initWithName:@"Image attachment"
                                             fileURL:nil
                                          contentType:contentType
                                       attachmentType:QMAttachmentContentTypeImage];
    attachment.image = image;
    
    return attachment;
}

@end
