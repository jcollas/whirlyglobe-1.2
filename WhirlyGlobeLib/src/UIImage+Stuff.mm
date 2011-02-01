//
//  UIImage+Stuff.m
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Stuff.h"


@implementation UIImage(Stuff)

-(NSData *)rawDataRetWidth:(unsigned int *)width height:(unsigned int *)height
{
	CGImageRef cgImage = self.CGImage;
	*width = CGImageGetWidth(cgImage);
	*height = CGImageGetHeight(cgImage);
	
	NSMutableData *retData = [NSMutableData dataWithLength:(*width)*(*height)*4];
	CGContextRef theContext = CGBitmapContextCreate((void *)[retData bytes], *width, *height, 8, (*width) * 4, CGImageGetColorSpace(cgImage), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(theContext, CGRectMake(0.0, 0.0, (CGFloat)(*width), (CGFloat)(*height)), cgImage);
	CGContextRelease(theContext);
	
	return retData;
}

@end
