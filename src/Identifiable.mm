/*
 *  identifiable.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/7/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "Identifiable.h"

namespace WhirlyGlobe
{
	
static unsigned long curId = 0;

Identifiable::Identifiable()
{ 
	myId = ++curId; 
}
	
SimpleIdentity Identifiable::genId()
{
	return ++curId;
}

}
