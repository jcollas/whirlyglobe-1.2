/*
 *  Identifiable.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/7/11.
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

