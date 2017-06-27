//
//  QMRequestOperation.h
//  QMServicesDevelopment
//
//  Created by Vitaliy Gurkovsky on 6/26/17.
//

#import "QMAsynchronousOperation.h"

@interface QMRequestOperation : QMAsynchronousOperation
@property (nonatomic, strong, readonly) QBRequest *request;

+ (instancetype)asynchronousOperationWithID:(NSString *)operationID
                                    request:(QBRequest *)requst
                                      queue:(NSOperationQueue *)queue;

@end
