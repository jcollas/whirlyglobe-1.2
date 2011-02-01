/*
 *  GridLines.cpp
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "GridLines.h"

namespace WhirlyGlobe
{
	
void GridLineModel::clear()
{
	for (unsigned int ii=0;ii<drawables.size();ii++)
		delete drawables[ii];
	drawables.clear();
}

GridLineModel::~GridLineModel()
{
	clear();
}

// Generate grid lines covering the earth model
void GridLineModel::generate(SphericalEarthModel *earthModel)
{
	clear();
	
	std::vector<Cullable *> &cullables = earthModel->getCullables();
	for (unsigned int ii=0;ii<cullables.size();ii++)
	{
		// We'll set up grid lines at each degree to cover this chunk
		Cullable *cullable = cullables[ii];
		
		// Drawable containing just lines
		// Note: Not deeply efficient here
		Drawable *drawable = new Drawable();
		drawable->type = GL_LINES;
		drawable->textureId = 0;
		
		int startX = std::ceil(cullable->geoMbr.ll().x()/GridCellSize);
		int endX = std::floor(cullable->geoMbr.ur().x()/GridCellSize);
		int startY = std::ceil(cullable->geoMbr.ll().y()/GridCellSize);
		int endY = std::floor(cullable->geoMbr.ur().y()/GridCellSize);
		
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
		
		cullable->addDrawable(drawable);
	}
}

}
