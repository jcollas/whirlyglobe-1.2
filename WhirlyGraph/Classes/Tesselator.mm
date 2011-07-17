//
//  Tesselator.cpp
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/17/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <list>
#import "Tesselator.h"

using namespace WhirlyGlobe;

bool SegmentIntersection(const Point2f &a0,const Point2f &a1,const Point2f &b0,const Point2f &b1,Point2f *iPt,float *retS,float *retT)
{
	float denom = a1.y()*(b0.x()-b1.x()) + a0.y()*(b1.x()-b0.x()) + (a0.x()-a1.x())*(b0.y()-b1.y());
	if (denom == 0.0)
		return true;
    
	float s = (-b0.y()*b1.x() + a0.y()*(-b0.x()+b1.x()) + a0.x()*(b0.y()-b1.y()) + b0.x()*b1.y())/denom;
	float t = (a0.y()*(a1.x()-b0.x()) + a1.y()*b0.x() - a1.x()*b0.y() + a0.x()*(b0.y()-a1.y()))/denom;
    
	if (0.0 <= s && s <= 1.0 &&
		0.0 <= t && t <= 1.0)
	{
		// Calculate the point and return
		if (iPt)
			*iPt = b0 + (b1-b0)*t;
		if (retS)
			*retS = s;
		if (retT)
			*retT = t;
        
		return true;
	} return false;
}

Point2f ClosestPointToSegment(const Point2f &pt,const Point2f &p0,const Point2f &p1,double *t)
{
	double dx = p1.x()-p0.x(), dy = p1.y()-p0.y();
	double denom = dx*dx+dy*dy;
    
	if (denom == 0)
		return p0;
    
	double u = ((pt.x()-p0.x())*(p1.x()-p0.x()) + (pt.y() - p0.y())*(p1.y() - p0.y()))/denom;
    
	// Point is somewhere on line segment, so calculate it
	if (u >= 0 && u <= 1.0)
	{
		if (t)
			*t = u;
		return Point2f(p0.x()+dx*u,p0.y()+dy*u);
	}
    
	// Closest must be one of the end points
    float mdx = p0.x()-pt.x(), mdy = p0.y()-pt.y();
	float dist2_0 = mdx*mdx+mdy*mdy;
    mdx = p1.x()-pt.x();  mdy = p1.y()-pt.y();
	float dist2_1 = mdx*mdx+mdy*mdy;
	if (dist2_0 < dist2_1)
	{
		if (t)
			*t = 0.0;
		return p0;
	} else {
		if (t)
			*t = 1.0;
		return p1;
	}
}

void TesselateRing(const VectorRing &ring,std::vector<VectorRing> &rets)
{
	static int count = 0;
	count++;
    
    int startRet = rets.size();
    
//    printf("TesselateRing Input: ");
//    for (unsigned int ii=0;ii<ring.size();ii++)
//        printf("(%f,%f) ",ring[ii].x(),ring[ii].y());
//    printf("\n");
    
	// Simple cases
	if (ring.size() < 3)
		return;
    
	if (ring.size() == 3)
	{
		rets.push_back(ring);
		return;
	}
    
	// Convert to a linked list
	std::list<Point2f> poly;
	for (unsigned int ii=0;ii<ring.size();ii++)
		poly.push_back(ring[ii]);
    std::reverse(poly.begin(),poly.end());
    
	// Whittle down the polygon until there's 3 left
	while (poly.size() > 3)
	{
		std::list<Point2f>::iterator bestPt = poly.end();
		std::list<Point2f>::iterator prevBestPt = poly.end();
		std::list<Point2f>::iterator nextBestPt = poly.end();
        
		// Look for the best point
		std::list<Point2f>::iterator prevPt = poly.end(); --prevPt;
		std::list<Point2f>::iterator pt = poly.begin();
		std::list<Point2f>::iterator nextPt = poly.begin(); nextPt++;
		while (pt != poly.end())
		{
			bool valid = true;
			// First, see if this is a valid triangle
			// Pt should be on the left of prev->next
			Point2f dir0(pt->x()-prevPt->x(),pt->y()-prevPt->y());
			Point2f dir1(nextPt->x()-prevPt->x(),nextPt->y()-prevPt->y());
			float z = dir0.x()*dir1.y() - dir0.y()*dir1.x();
            
			if (z < 0.0)
				valid = false;
            
			// Now make sure we're not intersecting anything else with the proposed edge
//			if (valid)
//			{				
//				for (std::list<Point2f>::iterator it = poly.begin();it!=poly.end();++it)
//				{
//					std::list<Point2f>::iterator nextIt = it;  ++nextIt;
//					if (nextIt == poly.end())
//						nextIt = poly.begin();
//                    
//					// Don't look at anything connected to the triangle we may form
//					if (it == prevPt || it == pt || it == nextPt || nextIt == prevPt)
//						continue;
//                    
//					Point2f p0 = *it;
//					Point2f p1 = *nextIt;
//					if (SegmentIntersection(p0,p1,*prevPt,*nextPt,NULL,NULL,NULL))
//					{
//						valid = false;
//						break;
//					}
//				}
//			}
            
			// Check that none of the other points fall within the proposed triangle
			if (valid)
			{
				VectorRing newTri;
				newTri.push_back(*prevPt);
				newTri.push_back(*pt);
				newTri.push_back(*nextPt);
				for (std::list<Point2f>::iterator it = poly.begin();it!=poly.end();++it)
				{
					// Obviously the three points we're going to use don't count
					if (it == prevPt || it == nextPt || it == pt)
						continue;
                    
					if (PointInPolygon(*it,newTri))
					{
//                        printf("f");
						valid = false;
						break;
					} else {
//                        printf("s");
                    }
				}
//                printf("\n");
			}

            // any valid point will do, we're not going to optimize further
			if (valid)
			{
                bestPt = pt;
                prevBestPt = prevPt;
                nextBestPt = nextPt;
                
                break;
			}
            
			if ((++prevPt) == poly.end())
				prevPt = poly.begin();
			++pt;
			if ((++nextPt) == poly.end())
				nextPt = poly.begin();
		}
        
		// Form the triangle (bestPt-1,bestPt,bestPt+1)
		if (bestPt == poly.end())
		{
//            printf("Tesselate failure for %d input\n",(int)ring.size());
            break;
            
		} else {
			VectorRing newTri;
			newTri.push_back(*prevBestPt);
			newTri.push_back(*bestPt);
			newTri.push_back(*nextBestPt);
			rets.push_back(newTri);
		}
		poly.erase(bestPt);
	}
    
	// What's left should be a single triangle
	VectorRing lastTri;
	for (std::list<Point2f>::iterator it = poly.begin();it != poly.end();++it)
		lastTri.push_back(*it);
	rets.push_back(lastTri);
    
    for (unsigned int ii=startRet;ii<rets.size();ii++)
    {
        VectorRing &retTri = rets[ii];
        std::reverse(retTri.begin(),retTri.end());
    }
    
//    printf("Tesselating ring in (%d) out (%d)\n",(int)ring.size(),(int)rets.size());
}