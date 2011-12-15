/*
 *  GridClipper.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 7/16/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "WhirlyVector.h"
#import "WhirlyGeometry.h"
#import "VectorData.h"

namespace WhirlyGlobe
{

/** Clip Loop to Grid will clip the given areal loop to a grid specified by the origin and spacing
    and return the results as individual loops.  This is used by the loft layer.
  */
bool ClipLoopToGrid(const WhirlyGlobe::VectorRing &ring,Point2f org,Point2f spacing,std::vector<WhirlyGlobe::VectorRing> &rets);

}
