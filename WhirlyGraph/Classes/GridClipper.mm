//
//  GridClipper.cpp
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/16/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#include "GridClipper.h"

using namespace WhirlyGlobe;

//using Polygon = List<FloatPoint>;
//using Polygons = List<List<FloatPoint>>;

// Clip the given loop to the given MBR
bool ClipLoopToMbr(const WhirlyGlobe::VectorRing &ring,const Mbr &mbr,std::vector<VectorRing> &rets)
{
//    Polygon subject = new Polygon(ring.size());
//    for (unsigned int ii=0;ii<ring.size();ii++)
        
    return true;
}

// Clip the given loop to the given grid (org and spacing)
// Return true on success and the new polygons in the rets
// Note: Not deeply efficient
bool ClipLoopToGrid(const WhirlyGlobe::VectorRing &ring,Point2f org,Point2f spacing,std::vector<WhirlyGlobe::VectorRing> &rets)
{
    Mbr mbr(ring);
    
    int ll_ix = (int)std::floor((mbr.ll().x()-org.x())/spacing.x());
    int ll_iy = (int)std::floor((mbr.ll().y()-org.y())/spacing.y());
    int ur_ix = (int)std::ceil((mbr.ur().x()-org.x())/spacing.x());
    int ur_iy = (int)std::ceil((mbr.ur().y()-org.y())/spacing.y());
    
    // Start out with just the input ring
    std::vector<VectorRing> curPolys;
    curPolys.push_back(ring);
    
    // Clip in strips from left to right
    for (int ix=ll_ix;ix<=ur_ix;ix++)
    {
        for (unsigned int ii=0;ii<curPolys.size();ii++)
        {
            VectorRing &thisPoly = curPolys[ii];
            
            Point2f l0(mbr.ll().x(),mbr.ll().y());
            Point2f l1((ix+1)*spacing.x()+org.x(),mbr.ur().y());
            Mbr left(l0,l1);
            
            std::vector<VectorRing> leftStrip;
            ClipLoopToMbr(thisPoly,left,leftStrip);

            Point2f r0(ix*spacing.x()+org.x(),mbr.ll().y());
            Point2f r1(mbr.ur().x(),mbr.ur().y());
            Mbr right(r0,r1);
            std::vector<VectorRing> newCurPolys;
            ClipLoopToMbr(thisPoly,right,newCurPolys);
            curPolys = newCurPolys;
            
            // Now clip the left strip vertically
            // Note: Do this
        }
    }
    
    return true;
}