/*
 *  ShapeDisplay.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "VectorLayer.h"

using namespace WhirlyGlobe;

@implementation VectorLayer

- (id)initWithLoader:(VectorLoader *)inLoader
{
	if (self = [super init])
	{
		loader = inLoader;
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

// Just schedule processing for later
- (void)startWithThread:(WhirlyGlobeLayerThread *)layerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
	[self performSelector:@selector(process:) withObject:nil];
}

// Generate drawables, one per areal feature
- (void)process:(id)sender
{
	VectorShape *theData = NULL;
	if (theData = loader->getNextObject())
	{
		VectorAreal *theAreal = dynamic_cast<VectorAreal *>(theData);
		if (theAreal && (theAreal->loops.size() > 0))
		{
			for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
			{
				// Just doing the outer loop for now
				VectorRing &ring = theAreal->loops[ri];
				
				if (ring.size() > 2)
				{
					GeoMbr arealGeoMbr;
					
					// Set up a drawable for just this areal
					// Note: Could be a problem for lots of small areals
					BasicDrawable *drawable = new BasicDrawable();
					drawable->setType(GL_LINE_LOOP);
					
					for (unsigned int jj=0;jj<ring.size();jj++)
					{
						// Convert to real world coordinates and offset from the globe
						Point2f &geoPt = ring[jj];
						GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
						arealGeoMbr.addGeoCoord(geoCoord);
						Point3f norm = PointFromGeo(geoCoord);
						Point3f pt = norm * (1.0 + ShapeOffset);
						
						// Add to drawable
						drawable->addPoint(pt);
						drawable->addNormal(norm);
					}
					drawable->setGeoMbr(arealGeoMbr);
					
					scene->addChangeRequest(ChangeRequest::AddDrawableCR(drawable));
				}
			}
		}

		// Schedule the next one
		[self performSelector:@selector(process:) withObject:nil];
	}	
}

@end
