/*
 *  Cullable.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/1/11.
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

#import "Drawable.h"

namespace WhirlyGlobe
{	

/* Cullable unit
 This is a representation of cullable geometry.  It has
 geometry/direction info and a list of associated
 Drawables.
 Cullables are always rectangles in lon/lat.
 */
class Cullable : public Identifiable
{
public:
	Cullable() { }
	
	// Add the given drawable to our set
	void addDrawable(Drawable *drawable) { drawables.insert(drawable); }
	
	// Remove a given drawable if it's there
	void remDrawable(Drawable *drawable) { std::set<Drawable *>::iterator it = drawables.find(drawable);  if (it != drawables.end()) drawables.erase(it); }
	
	const std::set<Drawable *> &getDrawables() const { return drawables; }

	GeoMbr getGeoMbr() const { return geoMbr; }
	void setGeoMbr(const GeoMbr &inMbr);
	
public:	
	// 3D locations (in model space) of the corners
	Point3f cornerPoints[4];
	// Normal vectors (in model space) for the corners
	Vector3f cornerNorms[4];
	// Geographic coordinates of our bounding box
	GeoMbr geoMbr;
	
	std::set<Drawable *> drawables;
};

}
