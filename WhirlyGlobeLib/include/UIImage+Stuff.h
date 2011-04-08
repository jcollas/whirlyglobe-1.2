//
//  UIImage+Stuff.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/11/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage(Stuff)

// Get out the raw data
-(NSData *)rawDataRetWidth:(unsigned int *)width height:(unsigned int *)height;

@end
