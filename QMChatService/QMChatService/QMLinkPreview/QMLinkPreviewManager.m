//
//  QMLinkPreviewManager.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/3/17.
//
//

#import "QMLinkPreviewManager.h"

@implementation QMLinkPreviewManager

- (void)linkPreviewForURL:(NSURL *)url withCompletion:(QMLinkPreviewCompletionBlock)completion {
    
    [[NSURLSession sharedSession] dataTaskWithURL:url
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    
                                }];
    
}

@end
