//
//  TextureGroup.mm
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+Stuff.h"
#import "TextureGroup.h"

@implementation TextureGroup

@synthesize baseName,ext;
@synthesize numX,numY;

// Initialize with the full info we need
- (id) initWithBase:(NSString *)base ext:(NSString *)extName numX:(unsigned int)x numY:(unsigned int)y
{
	if (self = [super init])
	{
		self.baseName = base;
		self.ext = extName;
		numX = x;
		numY = y;
	}
	
	return self;
}

// Generate a file name for loading a given piece
- (NSString *) generateFileNameX:(unsigned int)x y:(unsigned int)y
{
	if (x >= numX || y >= numY)
		return nil;
	
	return [NSString stringWithFormat:@"%@_%dx%d",baseName,x,y];
}

@end
