/*
 *  SphericalEarth.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/11/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "SphericalEarthLayer.h"
#import "UIImage+Stuff.h"
#import "GlobeMath.h"

@interface SphericalEarthLayer()
@property (nonatomic,retain) TextureGroup *texGroup;
@end

@implementation SphericalEarthLayer

@synthesize texGroup;

- (id)initWithTexGroup:(TextureGroup *)inTexGroup
{
	if ((self = [super init]))
	{
		self.texGroup = inTexGroup;
		xDim = texGroup.numX;
		yDim = texGroup.numY;
	}
	
	return self;
}

- (void)dealloc
{
	self.texGroup = nil;
	
	[super dealloc];
}

// Set up the next chunk to build and schedule it
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
	chunkX = chunkY = 0;
	[self performSelector:@selector(process:) withObject:nil];
}

using namespace WhirlyGlobe;

// Generate a list of drawables based on sphere, but broken
//  up to match the given texture group
- (void)process:(id)sender
{
	// Unit size of each tesselation, basically
	GeoCoord geoIncr(2*M_PI/(texGroup.numX*SphereTessX),M_PI/(texGroup.numY*SphereTessY));
	
	// Texture increment for each tesselation
	TexCoord texIncr(1.0/(float)SphereTessX,1.0/(float)SphereTessY);
	
	// We're viewing this as a parameterization from ([0->1.0],[0->1.0]) so we'll
	//  break up these coordinates accordingly
	Point2f paramSize(1.0/(texGroup.numX*SphereTessX),1.0/(texGroup.numY*SphereTessY));
	// Need the four corners to set up the cullable
	GeoCoord geoLL(-M_PI + (chunkX*SphereTessX)*geoIncr.x(),-M_PI/2.0 + (chunkY*SphereTessY)*geoIncr.y());
	GeoCoord geoUR(geoLL.x()+SphereTessX*geoIncr.x(),geoLL.y()+SphereTessY*geoIncr.y());
	
	// We'll set up and fill in the drawable
	BasicDrawable *chunk = new BasicDrawable((SphereTessX+1)*(SphereTessY+1),2*SphereTessX*SphereTessY);
	chunk->setType(GL_TRIANGLES);
//	chunk->setType(GL_POINTS);
	chunk->setGeoMbr(GeoMbr(geoLL,geoUR));
	
	// Generate points, texture coords, and normals first
	for (unsigned int iy=0;iy<SphereTessY+1;iy++)
		for (unsigned int ix=0;ix<SphereTessX+1;ix++)
		{
			// Generate the geographic location and clamp for safety
			GeoCoord geoLoc(-M_PI + (chunkX*SphereTessX+ix)*geoIncr.x(),-M_PI/2.0 + (chunkY*SphereTessY+iy)*geoIncr.y());
			if (geoLoc.x() < -M_PI)  geoLoc.x() = -M_PI;
			if (geoLoc.x() > M_PI) geoLoc.x() = M_PI;
			if (geoLoc.y() < -M_PI/2.0)  geoLoc.y() = -M_PI/2.0;
			if (geoLoc.y() > M_PI/2.0) geoLoc.y() = M_PI/2.0;
			
			// Physical location from that
			Point3f loc = PointFromGeo(geoLoc);
			
			// Do the texture coordinate seperately
			TexCoord texCoord(ix*texIncr.x(),1.0f-iy*texIncr.y());
			if (texCoord.x() > 1.0)  texCoord.x() = 1.0;
			if (texCoord.y() > 1.0)  texCoord.y() = 1.0;
			
			chunk->addPoint(loc);
			chunk->addTexCoord(texCoord);
			chunk->addNormal(loc);
		}
	
	// Two triangles per cell
	for (unsigned int iy=0;iy<SphereTessY;iy++)
	{
		for (unsigned int ix=0;ix<SphereTessX;ix++)
		{
			BasicDrawable::Triangle triA,triB;
			triA.verts[0] = iy*(SphereTessX+1)+ix;
			triA.verts[1] = iy*(SphereTessX+1)+(ix+1);
			triA.verts[2] = (iy+1)*(SphereTessX+1)+(ix+1);
			triB.verts[0] = triA.verts[0];
			triB.verts[1] = triA.verts[2];
			triB.verts[2] = (iy+1)*(SphereTessX+1)+ix;
			chunk->addTriangle(triA);
			chunk->addTriangle(triB);
		}
	}
	
	// Now for the changes to the scenegraph
	std::vector<ChangeRequest *> changeRequests;
	
	// Ask for a new texture and wire it to the drawable
	Texture *tex = new Texture([texGroup generateFileNameX:chunkX y:chunkY],texGroup.ext);
	changeRequests.push_back(new AddTextureReq(tex));
	chunk->setTexId(tex->getId());
	changeRequests.push_back(new AddDrawableReq(chunk));
	
	// This should make the changes appear
	scene->addChangeRequests(changeRequests);
	
	//	if (chunk->type == GL_POINTS)
	//		chunk->textureId = 0;

	// Move on to the next chunk
	if (++chunkX >= xDim)
	{
		chunkX = 0;
		chunkY++;
	}
	
	// Schedule the next chunk
	if (chunkY < yDim)
		[self performSelector:@selector(process:) withObject:nil];
	else {
//		NSLog(@"Spherical Earth layer done");
	}

}

@end
