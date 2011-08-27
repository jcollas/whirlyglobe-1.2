//
//  GridClipper.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/16/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <WhirlyGlobe/WhirlyGlobe.h>

// Clip a loop to the given grid
bool ClipLoopToGrid(const WhirlyGlobe::VectorRing &ring,Point2f org,Point2f spacing,std::vector<WhirlyGlobe::VectorRing> &rets);
