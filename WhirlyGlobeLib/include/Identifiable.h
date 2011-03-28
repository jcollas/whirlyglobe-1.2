/*
 *  Identifiable.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <set>

namespace WhirlyGlobe
{

// ID we'll pass around for scene objects
typedef unsigned long SimpleIdentity;
static const SimpleIdentity EmptyIdentity = 0;
    
typedef std::set<SimpleIdentity> SimpleIDSet;

// Simple unique ID base class
// We're not expecting very many of these at once
class Identifiable
{
public:
	// Construct with a new ID
	// Note: This may not work with multiple threads
	Identifiable();
	virtual ~Identifiable() { }
	
	// Return the identity
	SimpleIdentity getId() const { return myId; }
	
	// Think carefully before setting this
	void setId(SimpleIdentity inId) { myId = inId; }

	// Generate a new ID without an object
	static SimpleIdentity genId();
    
    // Used for sorting
    bool operator < (const Identifiable &that) { return myId < that.myId; }
		
protected:
	SimpleIdentity myId;
};
	
// Used to sort identifiables in a set or similar STL thing
typedef struct
{
	bool operator () (const Identifiable *a,const Identifiable *b) { return a->getId() < b->getId(); }
} IdentifiableSorter;

}

