/*
 *  ShapeReader.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "VectorData.h"
#import "GlobeMath.h"

namespace WhirlyGlobe
{

/* Shape File Reader
	Open a shapefile and return the features as requested.
 */
class ShapeReader : public VectorReader
{
public:
	ShapeReader(NSString *fileName);
	virtual ~ShapeReader();
	
	// Return true if we managed to load the file
	virtual bool isValid();
	
	// Return the next feature
	virtual VectorShapeRef getNextObject(const StringSet *filterAttrs);
    
    // We can do random seeking
    virtual bool canReadByIndex() { return true; }
    
    virtual unsigned int getNumObjects();
    
    virtual VectorShapeRef getObjectByIndex(unsigned int vecIndex,const StringSet *filter);
    
protected:
	void *shp;
	void *dbf;
	int where,numEntity,shapeType;
	double minBound[4], maxBound[4];
};

}
