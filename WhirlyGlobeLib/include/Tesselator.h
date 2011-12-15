/*
 *  Tesselator.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 7/17/11.
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

/** Tesselate the given ring, returning a list of triangles.
    This is a fairly simple tesselator. */
void TesselateRing(const WhirlyGlobe::VectorRing &ring,std::vector<WhirlyGlobe::VectorRing> &rets);
}
