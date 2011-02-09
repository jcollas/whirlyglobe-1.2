/*
 *  ShapeLoader.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "VectorLayer.h"

namespace WhirlyGlobe
{

/* Shape File Loader
	Open a shapefile and return the features as requested.
 */
class ShapeLoader : public VectorLoader
{
public:
	ShapeLoader(NSString *fileName);
	virtual ~ShapeLoader();
	
	// Return true if we managed to load the file
	virtual bool isValid();
	
	// Return the next feature
	virtual VectorShape *getNextObject();
	
protected:
	void *shp;
	void *dbf;
	int where,numEntity,shapeType;
	double minBound[4], maxBound[4];
};

}
