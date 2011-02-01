/*
 *  GridLines.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "SphericalEarth.h"

namespace WhirlyGlobe
{
	
static const float GlobeLineOffset = 0.01;
static const float GridCellSize = 3*(float)M_PI/180.0;

/* Grid Line Model
	Generates a set of grid lines corresponding to lon/lat
 */
class GridLineModel
{
public:
	GridLineModel() { }
	~GridLineModel();
	
	// Generate drawables for lines wrapping around the earth
	// We're just going to stick our drawables in the earth model's cullables
	void generate(SphericalEarthModel *earthModel);
	
protected:
	void clear();
	
	std::vector<Drawable *> drawables;
};

}
