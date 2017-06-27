//
//  QMRequestOperation.m
//  QMServicesDevelopment
//
//  Created by Vitaliy Gurkovsky on 6/26/17.
//

#import "QMRequestOperation.h"

@implementation QMRequestOperation

- (void)main {
    [self.request.task resume];
}


- (void)cancel {
    
    [self.request cancel];
    [super cancel];
}


@end
