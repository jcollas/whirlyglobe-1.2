//
//  NSDictionary+Stuff.m
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+Stuff.h"

@implementation NSDictionary(Stuff)

- (id)objectForKey:(NSString *)name checkType:(id)theType default:(id)theDefault
{
    id what = [self objectForKey:name];
    if (!what || ![what isKindOfClass:theType])
        return theDefault;
    
    return what;
}

- (float)floatForKey:(NSString *)name default:(float)theDefault
{
    id what = [self objectForKey:name];
    if (!what || ![what isKindOfClass:[NSNumber class]])
        return theDefault;
    
    NSNumber *num = what;
    return [num floatValue];
}

- (int)intForKey:(NSString *)name default:(int)theDefault
{
    id what = [self objectForKey:name];
    if (!what || ![what isKindOfClass:[NSNumber class]])
        return theDefault;
    
    NSNumber *num = what;
    return [num intValue];
}

- (BOOL)boolForKey:(NSString *)name default:(BOOL)theDefault
{
    id what = [self objectForKey:name];
    if (!what || ![what isKindOfClass:[NSNumber class]])
        return theDefault;
    
    NSNumber *num = what;
    return [num boolValue];
}


@end
