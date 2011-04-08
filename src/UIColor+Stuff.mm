//
//  UIColor+Stuff.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 3/15/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "UIColor+Stuff.h"

using namespace WhirlyGlobe;

@implementation UIColor(Stuff)

- (RGBAColor) asRGBAColor
{
    RGBAColor color;
    int numComponents = CGColorGetNumberOfComponents(self.CGColor);
    const CGFloat *colors = CGColorGetComponents(self.CGColor);
    
    switch (numComponents)
    {
        case 2:
            color.r = color.g = color.b = colors[0] * 255;
            color.a = colors[1] * 255;
            break;
        case 4:
            color.r = colors[0];
            color.g = colors[1];
            color.b = colors[2];
            color.a = colors[3];
            break;
        default:
            color.r = color.g = color.b = color.a = 255;
            color.a = 255;
            break;
    }
    
    return color;
}

@end
