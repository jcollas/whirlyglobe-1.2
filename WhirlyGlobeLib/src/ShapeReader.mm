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
    
unsigned int ShapeReader::getNumObjects()
{
    return numEntity;
}

// Return a single shape by index
VectorShapeRef ShapeReader::getObjectByIndex(unsigned int vecIndex,const StringSet *filterAttrs)
{
	SHPObject *thisShape = SHPReadObject((SHPInfo *)shp, vecIndex);
	
	// Copy over vertices (in 2d)
	bool startOne = true;
	VectorArealRef areal = VectorAreal::createAreal();
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
    areal->initGeoMbr();
	
	SHPDestroyObject(thisShape);
	
	// Attributes
	char attrTitle[12];
	int attrWidth, numDecimals;
	NSMutableDictionary *attrDict = [[[NSMutableDictionary alloc] init] autorelease];
	areal->setAttrDict(attrDict);
	DBFHandle dbfHandle = (DBFHandle)dbf;
	int numDbfRecord = DBFGetRecordCount(dbfHandle);
	if (vecIndex < numDbfRecord)
	{
		for (unsigned int ii = 0; ii < DBFGetFieldCount(dbfHandle); ii++)
		{
			DBFFieldType attrType = DBFGetFieldInfo(dbfHandle, ii, attrTitle, &attrWidth, &numDecimals);
            // If we have a set of filter attrs, skip this one if it's not there
            if (filterAttrs && (filterAttrs->find(attrTitle) == filterAttrs->end()))
                continue;
			NSString *attrTitleStr = [NSString stringWithFormat:@"%s",attrTitle];
			
			if (!DBFIsAttributeNULL(dbfHandle, vecIndex, ii))
			{
				switch (attrType)
				{
					case FTString:
					{
						const char *str = DBFReadStringAttribute(dbfHandle, vecIndex, ii);
                        NSString *newStr = [NSString stringWithCString:str encoding:NSASCIIStringEncoding];
                        if (newStr)
                            [attrDict setObject:newStr forKey:attrTitleStr];
                        //						[attrDict setObject:[NSString stringWithFormat:@"%s",str] forKey:attrTitleStr];
					}
						break;
					case FTInteger:
					{
						NSNumber *num = [NSNumber numberWithInt:DBFReadIntegerAttribute(dbfHandle, vecIndex, ii)];
						[attrDict setObject:num forKey:attrTitleStr];
					}
						break;
					case FTDouble:
					{
						NSNumber *num = [NSNumber numberWithDouble:DBFReadDoubleAttribute(dbfHandle, vecIndex, ii)];
						[attrDict setObject:num forKey:attrTitleStr];
					}
						break;
                    default:
                        break;
				}
			}
		}
	}
	
	return areal;    
}

// Return the next shape
VectorShapeRef ShapeReader::getNextObject(const StringSet *filterAttrs)
{
	// Reached the end
	if (where >= numEntity)
		return VectorShapeRef();
	
	// Only doing polygons at the moment
	if (!(shapeType == SHPT_POLYGON || shapeType == SHPT_POLYGONZ))
		return VectorShapeRef();
	
    VectorShapeRef retShape = getObjectByIndex(where, filterAttrs);
    where++;
    
    return retShape;
}
	
}
