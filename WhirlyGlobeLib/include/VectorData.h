/*
 *  VectorData.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 3/7/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import <math.h>
#import <vector>
#import <set>
#import "Drawable.h"

namespace WhirlyGlobe
{
	
// Base class for vector shapes
// Basically here so we can dynamic cast
class VectorShape : public Identifiable
{
public:
	VectorShape();
	virtual ~VectorShape();
	
	SimpleIdentity getDrawableId() const;
	void setDrawableId(SimpleIdentity inId);
	
	// Set the attribute dictionary
	void setAttrDict(NSMutableDictionary *newDict);
	
	// Return the attr dict
	NSMutableDictionary *getAttrDict();    
    // Calculate the geoMbr
    virtual GeoMbr calcGeoMbr() = 0;
	
protected:
	// If set, points to drawable
	SimpleIdentity drawableId;
	// Attributes for this feature
	NSMutableDictionary *attrDict;
};

typedef std::vector<Point2f> VectorRing;

// Areal feature
class VectorAreal : public VectorShape
{
public:
    virtual ~VectorAreal();
    virtual GeoMbr calcGeoMbr();
    
	std::vector<VectorRing> loops;
	GeoMbr geoMbr;
};
	
// Linear feature
class VectorLinear : public VectorShape
{
public:
	VectorRing pts;
};
	
// Points(s) feature
// Be prepared for one or more that share the same attributes
class VectorPoints : public VectorShape
{
public:
	VectorRing pts;
};

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
	virtual VectorShape *getNextObject() = 0;
};
	
/* Vector Pool
	This collects up all the output from a Vector Loader in one
	place.  If you find yourself using one, you probably need
    to do a bit more data structure design.
	Note: Do some more data structure design.
 */
class VectorPool
{
public:
	VectorPool(VectorReader *reader) : reader(reader), done(false) { }
	virtual ~VectorPool();
	
	// Call this every so often to keep reading vector data
	void update();
	
	// Check if we're dong loading
	bool isDone() { return done; }
	
	// Data read so far.  Read, but don't write
	// Be sure to only access these in the same thread your loader lives in
	std::vector<VectorAreal *> areals;
	std::vector<VectorLinear *> linears;
	std::vector<VectorPoints *> points; // points's
	
protected:
	bool done;
	VectorReader *reader;
};
	
}