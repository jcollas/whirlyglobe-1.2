//
//  UIColor+Stuff.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/15/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhirlyVector.h"

@interface UIColor(Stuff)

// Convert to an RGBA Color
- (WhirlyGlobe::RGBAColor) asRGBAColor;

@end
