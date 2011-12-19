/*
 *  SphericalEarth.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/11/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <UIKit/UIKit.h>
#import "SphericalEarthLayer.h"
#import "UIImage+Stuff.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;

@interface SphericalEarthLayer()
@property (nonatomic,retain) TextureGroup *texGroup;
@property (nonatomic,retain) NSString *cacheName;
@end

@implementation SphericalEarthLayer

@synthesize texGroup;
@synthesize cacheName;
@synthesize fade;

- (id)initWithTexGroup:(TextureGroup *)inTexGroup
{
    return [self initWithTexGroup:inTexGroup cacheName:nil];
}

- (id)initWithTexGroup:(TextureGroup *)inTexGroup cacheName:(NSString *)inCacheName;
{
	if ((self = [super init]))
	{
		self.texGroup = inTexGroup;
		xDim = texGroup.numX;
		yDim = texGroup.numY;
        savingToCache = false;
        self.cacheName = inCacheName;
        cacheWriter = NULL;
        fade = 0.0;
	}
	
	return self;
}

- (void)dealloc
{
	self.texGroup = nil;
    if (cacheWriter)
        delete cacheWriter;
    cacheWriter = NULL;
	
	[super dealloc];
}

- (void)saveToCacheName:(NSString *)inCacheName
{
    savingToCache = true;
    self.cacheName = inCacheName;
}

// Set up the next chunk to build and schedule it
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
	chunkX = chunkY = 0;
	[self performSelector:@selector(startProcess:) withObject:nil];
}

using namespace WhirlyGlobe;

// Load from a pregenerated cache
- (BOOL)loadFromCache
{
    RenderCacheReader cacheReader(cacheName);
    std::vector<Texture *> textures;
    std::vector<Drawable *> drawables;

    try
    {    
        // Try reading the cached drawables
        if (!cacheReader.getDrawablesAndTextures(textures,drawables))
            throw 1;

        // Should be as many drawables as textures
        if (texGroup.numX * texGroup.numY != drawables.size())
            throw 1;

        int whichDrawable = 0;
        for (unsigned int y = 0; y < texGroup.numY; y++)
            for (unsigned int x = 0; x < texGroup.numX; x++)
            {
                BasicDrawable *chunk = (BasicDrawable *)drawables[whichDrawable++];
                
                // Now for the changes to the scenegraph
                std::vector<ChangeRequest *> changeRequests;
                
                // Ask for a new texture and wire it to the drawable
                Texture *tex = new Texture([texGroup generateFileNameX:x y:y],texGroup.ext);
                tex->setWidth(texGroup.pixelsSquare);
                tex->setHeight(texGroup.pixelsSquare);
                changeRequests.push_back(new AddTextureReq(tex));
                chunk->setTexId(tex->getId());
                changeRequests.push_back(new AddDrawableReq(chunk));                
                scene->addChangeRequests(changeRequests);

                drawables[whichDrawable-1] = NULL;
            }
    }
    catch (...)
    {
        NSLog(@"Cache mismatch in SphericalEarthLayer.  Rebuilding.");
        
        for (unsigned int ii=0;ii<drawables.size();ii++)
            if (drawables[ii])
                delete drawables[ii];
        
        return FALSE;
    }
    
    return TRUE;
}

// First processing call.  Set things up
- (void)startProcess:(id)sender
{
    // See if there's a cache to read from first
    if (cacheName)
    {
        if (savingToCache)
        {
            // If we're saving things out, set up the cache writer
            cacheWriter = new RenderCacheWriter(cacheName);
            cacheWriter->setIgnoreTextures();
        } else {
            if ([self loadFromCache])
                return;            
        }            
    }

    // If we got here, we've got work to do.
    [self performSelector:@selector(process:) withObject:nil];
}

// Generate a list of drawables based on the sphere, but broken
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
    
    // Texture coordinates are actually scaled down a bit to
    //  deal with borders
    TexCoord adjTexMin,adjTexMax;
    Point2f adjTexSpan;
    [texGroup calcTexMappingOrg:&adjTexMin dest:&adjTexMax];
    adjTexSpan = adjTexMax - adjTexMin;
	
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
			TexCoord texCoord((ix*texIncr.x())*adjTexSpan.x()+adjTexMin.x(),adjTexMax.y()-(iy*texIncr.y())*adjTexSpan.y());
			
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
    tex->setWidth(texGroup.pixelsSquare);
    tex->setHeight(texGroup.pixelsSquare);
	changeRequests.push_back(new AddTextureReq(tex));
	chunk->setTexId(tex->getId());
    if (fade > 0)
    {
        NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
        chunk->setFade(curTime,curTime+fade);
    }
	changeRequests.push_back(new AddDrawableReq(chunk));
    
    // Save out to the cache if we've got one
    if (cacheWriter)
        cacheWriter->addDrawable(chunk);
	
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
        if (cacheWriter)
            delete cacheWriter;
        cacheWriter = NULL;
//		NSLog(@"Spherical Earth layer done");
	}

}

// Calculate the size of the smallest element
- (float)smallestTesselation
{
    float smallLon = 2*M_PI/(xDim*SphereTessX);
    float smallLat = M_PI/(yDim*SphereTessY);
    
    return std::min(smallLon,smallLat);
}

@end
