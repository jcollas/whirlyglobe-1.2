/*
 *  ShapeReader.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/2/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "ShapeReader.h"
#import "shapefil.h"

namespace WhirlyGlobe
{

ShapeReader::ShapeReader(NSString *fileName)
{
	const char *cFile =  [fileName cStringUsingEncoding:NSASCIIStringEncoding];
	shp = SHPOpen(cFile, "rb");
	if (!shp)
		return;
	dbf = DBFOpen(cFile, "rb");
	where = 0;	
	SHPGetInfo((SHPInfo *)shp, &numEntity, &shapeType, minBound, maxBound);
}
	
ShapeReader::~ShapeReader()
{
	if (shp)
		SHPClose((SHPHandle)shp);
	if (dbf)
		DBFClose((DBFHandle)dbf);
}
	
bool ShapeReader::isValid()
{
	return shp != NULL;
}

// Return the next shape
VectorShape *ShapeReader::getNextObject()
{
	// Reached the end
	if (where >= numEntity)
		return NULL;
	
	// Only doing polygons at the moment
	if (!(shapeType == SHPT_POLYGON || shapeType == SHPT_POLYGONZ))
		return NULL;
	
	SHPObject *thisShape = SHPReadObject((SHPInfo *)shp, where);
	
	// Copy over vertices (in 2d)
	bool startOne = true;
	VectorAreal *areal = new VectorAreal();
	VectorRing *ring = NULL;
	for (unsigned int jj = 0, iPart = 1; jj < thisShape->nVertices; jj++)
	{
		// Add rings to the given areal until we're done
		if ( iPart < thisShape->nParts && thisShape->panPartStart[iPart] == jj)
		{
			iPart++;
			startOne = true;
		}
		
		if (startOne)
		{
			areal->loops.resize(areal->loops.size()+1);
			ring = &areal->loops.back();
			startOne = false;
		}
		
		Point2f pt(DegToRad<float>(thisShape->padfX[jj]),DegToRad<float>(thisShape->padfY[jj]));
		ring->push_back(pt);
	}
	
	SHPDestroyObject(thisShape);
	
	// Attributes
	char attrTitle[12];
	int attrWidth, numDecimals;
	NSMutableDictionary *attrDict = [[[NSMutableDictionary alloc] init] autorelease];
	areal->setAttrDict(attrDict);
	DBFHandle dbfHandle = (DBFHandle)dbf;
	int numDbfRecord = DBFGetRecordCount(dbfHandle);
	if (where < numDbfRecord)
	{
		for (unsigned int ii = 0; ii < DBFGetFieldCount(dbfHandle); ii++)
		{
			DBFFieldType attrType = DBFGetFieldInfo(dbfHandle, ii, attrTitle, &attrWidth, &numDecimals);
			NSString *attrTitleStr = [NSString stringWithFormat:@"%s",attrTitle];
			
			if (!DBFIsAttributeNULL(dbfHandle, where, ii))
			{
				switch (attrType)
				{
					case FTString:
					{
						const char *str = DBFReadStringAttribute(dbfHandle, where, ii);
						[attrDict setObject:[NSString stringWithFormat:@"%s",str] forKey:attrTitleStr];
					}
						break;
					case FTInteger:
					{
						NSNumber *num = [NSNumber numberWithInt:DBFReadIntegerAttribute(dbfHandle, where, ii)];
						[attrDict setObject:num forKey:attrTitleStr];
					}
						break;
					case FTDouble:
					{
						NSNumber *num = [NSNumber numberWithDouble:DBFReadDoubleAttribute(dbfHandle, where, ii)];
						[attrDict setObject:num forKey:attrTitleStr];
					}
						break;
				}
			}
		}
	}
	
	where++;
	return areal;
}
	
}
