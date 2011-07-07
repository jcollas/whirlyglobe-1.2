/*
 *  VectorData.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 3/7/11.
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

#import <math.h>
#import <vector>
#import <set>
#import <boost/shared_ptr.hpp>
#import <boost/pointer_cast.hpp>
#import "Identifiable.h"
#import "WhirlyVector.h"
#import "WhirlyGeometry.h"

namespace WhirlyGlobe
{
	
// Base class for vector shapes
// Basically here so we can dynamic cast
class VectorShape : public Identifiable
{
public:	
	// Set the attribute dictionary
	void setAttrDict(NSMutableDictionary *newDict);
	
	// Return the attr dict
	NSMutableDictionary *getAttrDict();    
    // Return the geoMbr
    virtual GeoMbr calcGeoMbr() = 0;
	
protected:
	VectorShape();
	virtual ~VectorShape();

	// Attributes for this feature
	NSMutableDictionary *attrDict;
};

class VectorAreal;
class VectorLinear;
class VectorPoints;

// These are reference counted vectors.  Use these.
typedef boost::shared_ptr<VectorShape> VectorShapeRef;
typedef boost::shared_ptr<VectorAreal> VectorArealRef;
typedef boost::shared_ptr<VectorLinear> VectorLinearRef;
typedef boost::shared_ptr<VectorPoints> VectorPointsRef;

typedef std::vector<Point2f> VectorRing;

// Comparison function for the vector shape
// This is here to ensure we don't put in the same pointer twice
struct VectorShapeRefCmp
{
    bool operator()(const VectorShapeRef &a,const VectorShapeRef &b)
    { return a.get() < b.get(); }
};
    
typedef std::set<VectorShapeRef,VectorShapeRefCmp> ShapeSet;
    
// Calculate area of a loop
float CalcLoopArea(const VectorRing &);

// Areal feature
class VectorAreal : public VectorShape
{
public:
    // Creation function.  Use this instead of new
    static VectorArealRef createAreal();
    ~VectorAreal();
    
    virtual GeoMbr calcGeoMbr();
    void initGeoMbr();
    
    // True if the given point is within one of the loops
    bool pointInside(GeoCoord coord);
    
    // Sudivide to the given tolerance (in degrees)
    void subdivide(float tolerance);
        
	GeoMbr geoMbr;
	std::vector<VectorRing> loops;
    
protected:
    VectorAreal();
};
	
// Linear feature
class VectorLinear : public VectorShape
{
public:
    // Creation function.  Use instead of new
    static VectorLinearRef createLinear();
    ~VectorLinear();
    
    virtual GeoMbr calcGeoMbr();
    void initGeoMbr();

    // Sudivide to the given tolerance (in degrees)
    void subdivide(float tolerance);

	GeoMbr geoMbr;
	VectorRing pts;
    
protected:
    VectorLinear();
};
	
// Points(s) feature
// Be prepared for one or more that share the same attributes
class VectorPoints : public VectorShape
{
public:
    // Creation function.  Use instead of new
    static VectorPointsRef createPoints();
    ~VectorPoints();
    
    virtual GeoMbr calcGeoMbr();
    void initGeoMbr();

	GeoMbr geoMbr;
	VectorRing pts;
    
protected:
    VectorPoints();
};
    
typedef std::set<std::string> StringSet;
    
// Break any edge longer than the given length
// Returns true if it broke anything
void SubdivideEdges(const VectorRing &inPts,VectorRing &outPts,bool closed,float maxLen);

/* Vector Reader
   Base class for loading a vector data file.
   Fill this into hand data over to whomever wants it.
 */
class VectorReader
{
public:
    VectorReader() { }
    virtual ~VectorReader() { }
	
    // Return false if we failed to load
    virtual bool isValid() = 0;
	
    // Return one of the vector types
    // Keep enough state to figure out what the next one is
    // You can skip any attributes not named in the filter.  Or just ignore it.
    virtual VectorShapeRef getNextObject(const StringSet *filter) = 0;
    
    // Return true if this vector reader can seek and read
    virtual bool canReadByIndex() { return false; }
    
    // Return the total number of vectors objects
    virtual unsigned int getNumObjects() { return 0; }
    
    // Return an object that corresponds to the given index
    // You need to be able to seek in your file format for this
    // The filter works the same as for getNextObect()
    virtual VectorShapeRef getObjectByIndex(unsigned int vecIndex,const StringSet *filter)  { return VectorShapeRef(); }
};
        		
}