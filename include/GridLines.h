/*
 *  GridLines.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/25/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import "DataLayer.h"
#import "GlobeScene.h"

namespace WhirlyGlobe
{
	
static const float GlobeLineOffset = 0.01;
static const float GridCellSize = 3*(float)M_PI/180.0;

/* Grid Line Layer
	Sets up a set of grid lines
 */
class GridLineLayer
{
public:

	// Inherited from DataLayer
	virtual void init();

	// Generate drawables for lines wrapping around the earth
	virtual void process(GlobeScene *scene);
	
protected:
};

}
