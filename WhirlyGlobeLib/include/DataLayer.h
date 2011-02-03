/*
 *  DataLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <math.h>
#import <Foundation/Foundation.h>
#import "GlobeScene.h"

namespace WhirlyGlobe
{

/* Data Layer
	Used to overlay data on top of the globe.
	Layers are run in their own thread.
 */
class DataLayer
{
public:
	DataLayer() { };
	virtual ~DataLayer() { };
	
	// Do whatever initialization we need
	virtual void init() = 0;
	
	// Generate geometry here.  We don't modify the scene directly,
	//  just ask to have things added or removed
	virtual void process(GlobeScene *scene) = 0;
};

}
