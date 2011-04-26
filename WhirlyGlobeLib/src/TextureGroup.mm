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
@synthesize pixelsSquare,borderPixels;

- (id) initWithInfo:(NSString *)infoName;
{
    // This should be the info plist.  That has everything
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:infoName];
    if (!dict)
    {
        return nil;
    }

	if ((self = [super init]))
	{
        self.ext = [dict objectForKey:@"format"];
        self.baseName = [dict objectForKey:@"baseName"];
        numX = [[dict objectForKey:@"tilesInX"] intValue];
        numY = [[dict objectForKey:@"tilesInY"] intValue];
        pixelsSquare = [[dict objectForKey:@"pixelsSquare"] intValue];
        borderPixels = [[dict objectForKey:@"borderSize"] intValue];
	}
	
	return self;
}
                    
- (void)dealloc
{
    self.ext = nil;
    self.baseName = nil;
    
    [super dealloc];
}

// Generate a file name for loading a given piece
- (NSString *) generateFileNameX:(unsigned int)x y:(unsigned int)y
{
	if (x >= numX || y >= numY)
		return nil;
	
	return [NSString stringWithFormat:@"%@_%dx%d",baseName,x,y];
}

- (void)calcTexMappingOrg:(WhirlyGlobe::TexCoord *)org dest:(WhirlyGlobe::TexCoord *)dest
{
    org->u() = org->v() = (float)borderPixels/(float)pixelsSquare;
    dest->u() = dest->v() = 1.f - org->u();
}

@end
