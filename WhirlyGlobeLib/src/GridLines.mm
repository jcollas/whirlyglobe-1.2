/*
 *  GridLines.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "GridLines.h"
#import "GlobeMath.h"

@interface GridLayer()
@end

using namespace WhirlyGlobe;

@implementation GridLayer

- (id)initWithX:(unsigned int)inNumX Y:(unsigned int)inNumY
{
	if (self = [super init])
	{
		numX = inNumX;
		numY = inNumY;
	}
	
	return self;
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(GlobeScene *)inScene
{
	chunkX = 0;  chunkY = 0;
	scene = inScene;
	[self performSelector:@selector(process:) withObject:nil];
}

// Generate grid lines covering the earth model
- (void)process:(id)sender
{
	std::vector<ChangeRequest> changeRequests;

	GeoCoord geoIncr(2*M_PI/numX,M_PI/numY);
	GeoCoord geoLL(-M_PI + chunkX*geoIncr.x(),-M_PI/2.0 + chunkY*geoIncr.y());
	GeoMbr geoMbr(geoLL,geoLL+geoIncr);
		
	// Drawable containing just lines
	// Note: Not deeply efficient here
	BasicDrawable *drawable = new BasicDrawable();
	drawable->setType(GL_LINES);
	
	int startX = std::ceil(geoMbr.ll().x()/GridCellSize);
	int endX = std::floor(geoMbr.ur().x()/GridCellSize);
	int startY = std::ceil(geoMbr.ll().y()/GridCellSize);
	int endY = std::floor(geoMbr.ur().y()/GridCellSize);
	
	for (int x = startX;x <= endX; x++)
		for (int y = startY;y <= endY; y++)
		{
			// Start out with the points in 3-space
			// Note: Duplicating work
			Point3f norms[4],pts[4];
			norms[0] = PointFromGeo(GeoCoord(x*GridCellSize,y*GridCellSize));
			norms[1] = PointFromGeo(GeoCoord((x+1)*GridCellSize,y*GridCellSize));
			norms[2] = PointFromGeo(GeoCoord((x+1)*GridCellSize,GridCellSize*(y+1)));
			norms[3] = PointFromGeo(GeoCoord(GridCellSize*x,GridCellSize*(y+1)));
			
			// Nudge them out a little bit
			for (unsigned int ii=0;ii<4;ii++)
				pts[ii] = norms[ii] * (1.0 + GlobeLineOffset);
			
			// Add to drawable
			drawable->addPoint(pts[0]);
			drawable->addNormal(norms[0]);
			drawable->addPoint(pts[1]);
			drawable->addNormal(norms[1]);
			drawable->addPoint(pts[0]);
			drawable->addNormal(norms[0]);
			drawable->addPoint(pts[3]);
			drawable->addNormal(norms[3]);
			
		}
	
	scene->addChangeRequest(new AddDrawableReq(drawable));
	
	// Move on to the next chunk
	if (++chunkX >= numX)
	{
		chunkX = 0;
		chunkY++;
	}
	
	// Schedule the next chunk
	if (chunkY < numY)
		[self performSelector:@selector(process:) withObject:nil];	
}

@end
