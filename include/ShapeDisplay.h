/*
 *  ShapeDisplay.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <Foundation/Foundation.h>
#import "SphericalEarth.h"

namespace WhirlyGlobe
{

static const float ShapeOffset = 0.001;

// Simple shape representation
// One outline, no holes
class ShapeAreal
{
public:
	std::vector<Point2f> pts;
};
	
/* Shape File Model
	Overlays a shape file on top of the globe.
 */
class ShapeFileModel
{
public:
	ShapeFileModel(NSString *fileName);
	~ShapeFileModel();
	
	// Generate drawables for the shapefile
	// We'll wrap them around the earth, one drawable per areal
	// The drawables are inserted into the proper cullabes in the earth model
	void generate(SphericalEarthModel *earthModel);
	
protected:
	void clear();
	
	std::vector<ShapeAreal> areals;
	std::vector<Drawable *> drawables;
};

}
