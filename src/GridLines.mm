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

namespace WhirlyGlobe
{
	
// Generate grid lines covering the earth model
void GridLineLayer::process(GlobeScene *scene)
{
	std::vector<ChangeRequest> changeRequests;

	const Cullable *cullables = scene->getCullables();
	unsigned int numX,numY;
	scene->getCullableSize(numX, numY);
	
	for (unsigned int ii=0;ii<numX*numY;ii++)
	{
		// We'll set up grid lines at each degree to cover this chunk
		const Cullable &cullable = cullables[ii];
		
		// Drawable containing just lines
		// Note: Not deeply efficient here
		BasicDrawable *drawable = new BasicDrawable();
		drawable->setType(GL_LINES);
		
		GeoMbr geoMbr = cullable.getGeoMbr();
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
		
		changeRequests.push_back(ChangeRequest::AddDrawableCR(drawable));
	}
	
	scene->addChangeRequests(changeRequests);
}

}
