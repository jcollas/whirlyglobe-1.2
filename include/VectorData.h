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
typedef std::set<VectorShape *> ShapeSet;

// Areal feature
class VectorAreal : public VectorShape
{
public:
    virtual ~VectorAreal();
    virtual GeoMbr calcGeoMbr();
    void initGeoMbr();
    
    // True if the given point is within one of the loops
    bool pointInside(GeoCoord coord);
    
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
    
typedef std::set<VectorShape *> ShapeSet;
	
/* Vector Pool
    This collects the output from one or more readers in
    a single place, suitable for searches and such.
 */
class VectorPool
{
public:
	VectorPool();
	virtual ~VectorPool();
    
    // Add a reader.  Pool is responsible for deletion at this point
    void addReader(VectorReader *reader);
    
    // Add a shapefile (shortcut)
    void addShapeFile(NSString *fileName);
	
	// Call this every so often to keep reading vector data
	void update();
	
	// Check if we're done loading
	bool isDone();

    // Find all the shapes that match the given predicate
    // The predicate is applied to the attribute dictionaries
    void findMatches(NSPredicate *pred,ShapeSet &shapes);
    
    // Find areals that cover the given point
    void findArealsForPoint(GeoCoord coord,ShapeSet &shapes);
	
	// Data read so far.
	// Be sure to only access these in the same thread your loader lives in
	std::vector<VectorAreal *> areals;
	std::vector<VectorLinear *> linears;
	std::vector<VectorPoints *> points;
	
protected:
    int curReader;  // Which reader we're using
    std::vector<VectorReader *> readers;  // Readers in the queue
};
	
}