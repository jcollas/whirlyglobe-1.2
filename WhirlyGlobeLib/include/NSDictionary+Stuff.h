//
//  NSDictionary+Stuff.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary(Stuff)

// Return the object correspond to name if it's the right type
// Returns default if missing or wrong type
- (id)objectForKey:(NSString *)name checkType:(id)theType default:(id)theDefault;

// Return a float for the given name if it exists
// Returns default if not or wrong type
- (float)floatForKey:(NSString *)name default:(float)theDefault;

// Return an integer for the given name if it exists
// Returns default if not or wrong type
- (int)intForKey:(NSString *)name default:(int)theDefault;

// Return a boolean for the given name if it exists
// Returns default if not or wrong type
- (BOOL)boolForKey:(NSString *)name default:(BOOL)theDefault;

@end
