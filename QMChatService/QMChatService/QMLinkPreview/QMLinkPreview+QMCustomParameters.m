//
//  QMLinkPreview+QMCustomParameters.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/12/17.
//
//

#import "QMLinkPreview+QMCustomParameters.h"
#import <objc/runtime.h>

@implementation QMLinkPreview (QMCustomParameters)

//MARK: - Setters
- (void)setPreviewImage:(UIImage *)previewImage {
    
    objc_setAssociatedObject(self, @selector(previewImage), previewImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setIconImage:(UIImage *)iconImage {
    objc_setAssociatedObject(self, @selector(iconImage), iconImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//MARK: - Getters

- (UIImage *)previewImage {
    
    return objc_getAssociatedObject(self, @selector(previewImage));
}
- (UIImage *)iconImage {
    return objc_getAssociatedObject(self, @selector(iconImage));
}

@end
