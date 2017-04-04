//
//  QMLinkPreviewManager.h
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/3/17.
//
//

@class QMLinkPreview;
typedef void(^QMLinkPreviewCompletionBlock)(QMLinkPreview *linkPreview, NSError *error);

@interface QMLinkPreviewManager : NSObject

- (void)linkPreviewForURL:(NSURL *)url withCompletion:(QMLinkPreviewCompletionBlock)completion;

@end
