/*
 *  ShapeDisplay.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "WhirlyGeometry.h"
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
	for (ShapeMap::iterator it = shapes.begin();it != shapes.end();++it)
		delete it->second;
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
			if (theAreal->loops[0].size() > 2)
			{
				BasicDrawable *drawable = new BasicDrawable();
				drawable->setType(theAreal->loops.size() > 1 ? GL_LINES : GL_LINE_LOOP);
//				drawable->setType(GL_TRIANGLES);
				
				for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
				{
					VectorRing &ring = theAreal->loops[ri];					

					Point3f prevPt,prevNorm,firstPt,firstNorm;
					for (unsigned int jj=0;jj<ring.size();jj++)
					{
						// Convert to real world coordinates and offset from the globe
						Point2f &geoPt = ring[jj];
						GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
						theAreal->geoMbr.addGeoCoord(geoCoord);
						Point3f norm = PointFromGeo(geoCoord);
						Point3f pt = norm * (1.0 + ShapeOffset);
						
						// Add to drawable
						// Depending on the type, we do this differently
						if (drawable->getType() == GL_LINES || drawable->getType() == GL_TRIANGLES)
						{
							if (jj > 0)
							{
#if 1
								drawable->addPoint(prevPt);
								drawable->addPoint(pt);
								drawable->addNormal(prevNorm);
								drawable->addNormal(norm);
#else
								drawable->addRect(prevPt,prevNorm,pt,norm,ShapeOffset);
#endif
							} else {
								firstPt = pt;
								firstNorm = norm;
							}
							prevPt = pt;
							prevNorm = norm;
						} else {
							drawable->addPoint(pt);
							drawable->addNormal(norm);
						}
					}

					// Close the loop
					if (drawable->getType() == GL_LINES || drawable->getType() == GL_TRIANGLES)
					{
#if 1
						drawable->addPoint(prevPt);
						drawable->addPoint(firstPt);
						drawable->addNormal(prevNorm);
						drawable->addNormal(firstNorm);
#else
						drawable->addRect(prevPt,prevNorm,firstPt,firstNorm,ShapeOffset/4.0);
#endif
					}
				}

				drawable->setGeoMbr(theAreal->geoMbr);
				drawable->setColor(RGBAColor(128,128,128,255));
				theAreal->setDrawableId(drawable->getId());
				scene->addChangeRequest(ChangeRequest::AddDrawableCR(drawable));
				
				// Keep track of this for later
				shapes[theAreal->getId()] = theAreal;
			}
		}

		// Schedule the next one
		[self performSelector:@selector(process:) withObject:nil];
	}	
}

- (VectorShape *)findHitAtGeoCoord:(WhirlyGlobe::GeoCoord)geoCoord
{
	// Look through the shapes for an interior point
	for (ShapeMap::iterator it = shapes.begin(); it != shapes.end(); ++it)
	{
		VectorAreal *theAreal = dynamic_cast<VectorAreal *>(it->second);
		if (theAreal && theAreal->geoMbr.inside(geoCoord))
		{
			for (unsigned int ii=0;ii<theAreal->loops.size();ii++)
				if (PointInPolygon(geoCoord,theAreal->loops[ii]))
					return theAreal;
		}
	}
	
	return EmptyIdentity;
}

// Make an object visibly selected
- (void)selectObject:(WhirlyGlobe::SimpleIdentity)simpleId
{
	// Look for the corresponding shape
	ShapeMap::iterator it = shapes.find(simpleId);
	if (it != shapes.end())
	{
		SimpleIdentity drawId = it->second->getDrawableId();
		scene->addChangeRequest(ChangeRequest::ColorDrawableCR(drawId,RGBAColor(255,255,255,255)));
	}
}

// Clear outstanding selection
- (void)unSelectObject:(WhirlyGlobe::SimpleIdentity)simpleId
{
	// Look for the corresponding shape
	ShapeMap::iterator it = shapes.find(simpleId);
	if (it != shapes.end())
	{
		SimpleIdentity drawId = it->second->getDrawableId();
		scene->addChangeRequest(ChangeRequest::ColorDrawableCR(drawId,RGBAColor(128,128,128,255)));		
	}
}


@end
