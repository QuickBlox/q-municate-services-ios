//
//  QMLinkPreview.m
//  Pods
//
//  Created by Vitaliy Gurkovsky on 4/3/17.
//
//

#import "QMLinkPreview.h"

@implementation QMLinkPreview

- (NSString *)description{
    
    NSString *desc = [NSString stringWithFormat:
                      @"\r  url:%@\
                      \r    title:%@\
                      \r    description:%@\
                      \r    imageURL:%@\,",
                      _siteUrl,
                      _siteTitle,
                      _siteDescription,
                      _imageURL
                      ];
    
    return desc;
}

//MARK: - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        _siteUrl = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(siteUrl))];
        _siteTitle = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(siteTitle))];
        _siteDescription = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(siteDescription))];
        _imageURL = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(imageURL))];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.siteUrl forKey:NSStringFromSelector(@selector(siteUrl))];
    [aCoder encodeObject:self.siteTitle forKey:NSStringFromSelector(@selector(siteTitle))];
    [aCoder encodeObject:self.siteDescription forKey:NSStringFromSelector(@selector(siteDescription))];
    [aCoder encodeObject:self.imageURL forKey:NSStringFromSelector(@selector(imageURL))];
}

//MARK: - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    
    QMLinkPreview *copy = [[QMLinkPreview alloc] init];
    
    copy.siteUrl = [self.siteUrl copyWithZone:zone];
    copy.siteTitle = [self.siteTitle copyWithZone:zone];
    copy.siteDescription = [self.siteDescription copyWithZone:zone];
    copy.imageURL = [self.imageURL copyWithZone:zone];
    
    return copy;
}

@end
