//
//  QMMagicalRecord+ShorthandSupport.m
//  QMMagical Record
//
//  Created by Saul Mora on 3/6/12.
//  Copyright (c) 2012 QMMagical Panda Software LLC. All rights reserved.
//

#import "QMMagicalRecord+ShorthandSupport.h"
#import <objc/runtime.h>


static NSString * const kQMMagicalRecordCategoryPrefix = @"QM_";
#ifdef QM_SHORTHAND
static BOOL methodsHaveBeenSwizzled = NO;
#endif


//Dynamic shorthand method helpers
BOOL addQMMagicalRecordShortHandMethodToPrefixedClassMethod(Class class, SEL selector);
BOOL addQMMagicalRecordShorthandMethodToPrefixedInstanceMethod(Class klass, SEL originalSelector);

void swizzleInstanceMethods(Class originalClass, SEL originalSelector, Class targetClass, SEL newSelector);
void replaceSelectorForTargetWithSourceImpAndSwizzle(Class originalClass, SEL originalSelector, Class newClass, SEL newSelector);


@implementation QMMagicalRecord (ShorthandSupport)

#pragma mark - Support methods for shorthand methods

#ifdef QM_SHORTHAND
+ (BOOL) QM_resolveClassMethod:(SEL)originalSelector
{
    BOOL resolvedClassMethod = [self QM_resolveClassMethod:originalSelector];
    if (!resolvedClassMethod) 
    {
        resolvedClassMethod = addQMMagicalRecordShortHandMethodToPrefixedClassMethod(self, originalSelector);
    }
    return resolvedClassMethod;
}

+ (BOOL) QM_resolveInstanceMethod:(SEL)originalSelector
{
    BOOL resolvedClassMethod = [self QM_resolveInstanceMethod:originalSelector];
    if (!resolvedClassMethod) 
    {
        resolvedClassMethod = addQMMagicalRecordShorthandMethodToPrefixedInstanceMethod(self, originalSelector);
    }
    return resolvedClassMethod;
}

//In order to add support for non-prefixed AND prefixed methods, we need to swap the existing resolveClassMethod: and resolveInstanceMethod: implementations with the one in this class.
+ (void) updateResolveMethodsForClass:(Class)klass
{
    replaceSelectorForTargetWithSourceImpAndSwizzle(self, @selector(QM_resolveClassMethod:), klass, @selector(resolveClassMethod:));
    replaceSelectorForTargetWithSourceImpAndSwizzle(self, @selector(QM_resolveInstanceMethod:), klass, @selector(resolveInstanceMethod:));    
}

+ (void) swizzleShorthandMethods;
{
    if (methodsHaveBeenSwizzled) return;
    
    NSArray *classes = [NSArray arrayWithObjects:
                        [NSManagedObject class],
                        [NSManagedObjectContext class], 
                        [NSManagedObjectModel class], 
                        [NSPersistentStore class], 
                        [NSPersistentStoreCoordinator class], nil];
    
    [classes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Class klass = (Class)obj;
        
        [self updateResolveMethodsForClass:klass];
    }];
    methodsHaveBeenSwizzled = YES;
}
#endif

@end

#pragma mark - Support functions for runtime shorthand Method calling

void replaceSelectorForTargetWithSourceImpAndSwizzle(Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector)
{
    Method sourceClassMethod = class_getClassMethod(sourceClass, sourceSelector);
    Method targetClassMethod = class_getClassMethod(targetClass, targetSelector);
    
    Class targetMetaClass = objc_getMetaClass([NSStringFromClass(targetClass) cStringUsingEncoding:NSUTF8StringEncoding]);
    
    BOOL methodWasAdded = class_addMethod(targetMetaClass, sourceSelector,
                                          method_getImplementation(targetClassMethod),
                                          method_getTypeEncoding(targetClassMethod));
    
    if (methodWasAdded)
    {
        class_replaceMethod(targetMetaClass, targetSelector, 
                            method_getImplementation(sourceClassMethod), 
                            method_getTypeEncoding(sourceClassMethod));
    }
}

BOOL addQMMagicalRecordShorthandMethodToPrefixedInstanceMethod(Class klass, SEL originalSelector)
{
    NSString *originalSelectorString = NSStringFromSelector(originalSelector);
    if ([originalSelectorString hasPrefix:@"_"] || [originalSelectorString hasPrefix:@"init"]) return NO;
    
    if (![originalSelectorString hasPrefix:kQMMagicalRecordCategoryPrefix]) 
    {
        NSString *prefixedSelector = [kQMMagicalRecordCategoryPrefix stringByAppendingString:originalSelectorString];
        Method existingMethod = class_getInstanceMethod(klass, NSSelectorFromString(prefixedSelector));
        
        if (existingMethod) 
        {
            BOOL methodWasAdded = class_addMethod(klass, 
                                                  originalSelector, 
                                                  method_getImplementation(existingMethod), 
                                                  method_getTypeEncoding(existingMethod));
            
            return methodWasAdded;
        }
    }
    return NO;
}


BOOL addQMMagicalRecordShortHandMethodToPrefixedClassMethod(Class klass, SEL originalSelector)
{
    NSString *originalSelectorString = NSStringFromSelector(originalSelector);
    if (![originalSelectorString hasPrefix:kQMMagicalRecordCategoryPrefix]) 
    {
        NSString *prefixedSelector = [kQMMagicalRecordCategoryPrefix stringByAppendingString:originalSelectorString];
        Method existingMethod = class_getClassMethod(klass, NSSelectorFromString(prefixedSelector));
        
        if (existingMethod) 
        {
            Class metaClass = objc_getMetaClass([NSStringFromClass(klass) cStringUsingEncoding:NSUTF8StringEncoding]);
            BOOL methodWasAdded = class_addMethod(metaClass, 
                                                  originalSelector, 
                                                  method_getImplementation(existingMethod), 
                                                  method_getTypeEncoding(existingMethod));
            
            return methodWasAdded;
        }
    }
    return NO;
}

