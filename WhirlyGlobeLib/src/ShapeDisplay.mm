/*
 *  ShapeDisplay.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "ShapeDisplay.h"
#import "shapefil.h"

namespace WhirlyGlobe
{

// Load the shapefile and store the data
ShapeFileModel::ShapeFileModel(NSString *fileName)
{
	SHPHandle shp;
	shp = SHPOpen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "rb");
	if (!shp)
		throw (std::string) "Failed to open shapefile";
	
	// Work through the shapes
	int numEntity, shapeType;
	double minBound[4], maxBound[4];
	SHPGetInfo(shp, &numEntity, &shapeType, minBound, maxBound);
	// Note: Just taking areals for now
	if (shapeType == SHPT_POLYGON || shapeType == SHPT_POLYGONZ)
	{
		for (int ii = 0; ii < numEntity; ii++)
		{
			SHPObject *thisShape = SHPReadObject(shp, ii);

			// Copy over vertices (in 2d)
			bool startOne = true;
			ShapeAreal *areal = NULL;
			for (unsigned int jj = 0, iPart = 1; jj < thisShape->nVertices; jj++)
			{
				// There are multiple rings.  We need one areal per (for now)
				if ( iPart < thisShape->nParts && thisShape->panPartStart[iPart] == jj)
				{
					iPart++;
					startOne = true;
				}
				
				if (startOne)
				{
					areals.resize(areals.size()+1);
					areal = &areals.back();
					startOne = false;
				}
				
				Point2f pt(DegToRad<float>(thisShape->padfX[jj]),DegToRad<float>(thisShape->padfY[jj]));
				areal->pts.push_back(pt);
			}
			
			SHPDestroyObject(thisShape);
		}
	}
	
	SHPClose(shp);
}
	
void ShapeFileModel::clear()
{
	for (unsigned int ii=0;ii<drawables.size();ii++)
		delete drawables[ii];
	drawables.clear();
}

ShapeFileModel::~ShapeFileModel()
{
	clear();
}

// Generate drawables, one per areal feature
// Sort these into cullables from the earth model
void ShapeFileModel::generate(SphericalEarthModel *earthModel)
{
	// Work through the areals
	for (unsigned int ii=0;ii<areals.size();ii++)
	{
		ShapeAreal &areal = areals[ii];
		
		if (areal.pts.size() > 2)
		{
			GeoMbr arealGeoMbr;
			
			// Set up a drawable for just this areal
			// Note: Could be a problem for lots of small areals
			Drawable *drawable = new Drawable();
			drawables.push_back(drawable);
			drawable->type = GL_LINE_LOOP;
			drawable->textureId = 0;
		
			for (unsigned int jj=0;jj<areal.pts.size();jj++)
			{
				// Convert to real world coordinates and offset from the globe
				Point2f &geoPt = areal.pts[jj];
				GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
				arealGeoMbr.addGeoCoord(geoCoord);
				Point3f norm = PointFromGeo(geoCoord);
				Point3f pt = norm * (1.0 + ShapeOffset);
				
				// Add to drawable
				drawable->addPoint(pt);
				drawable->addNormal(norm);
			}
			
			// Add to the appropriate cullables
			std::vector<Cullable *> cullables;
			earthModel->overlapping(arealGeoMbr,cullables);
			for (unsigned int cc=0;cc<cullables.size();cc++)
				cullables[cc]->addDrawable(drawable);
		}
	}
}

}
