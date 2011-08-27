//
//  GridClipper.cpp
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/16/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "GridClipper.h"
#import "clipper.hpp"

using namespace WhirlyGlobe;
using namespace clipper;

float PolyScale = 1e14;

// Clip the given loop to the given MBR
bool ClipLoopToMbr(const WhirlyGlobe::VectorRing &ring,const Mbr &mbr,std::vector<VectorRing> &rets)
{
    Polygon subject(ring.size());
    for (unsigned int ii=0;ii<ring.size();ii++)
    {
        const Point2f &pt = ring[ii];
        subject[ii] = IntPoint(pt.x()*PolyScale,pt.y()*PolyScale);
    }
    Polygon clip(4);
    clip[0] = IntPoint(mbr.ll().x()*PolyScale,mbr.ll().y()*PolyScale);
    clip[1] = IntPoint(mbr.ur().x()*PolyScale,mbr.ll().y()*PolyScale);
    clip[2] = IntPoint(mbr.ur().x()*PolyScale,mbr.ur().y()*PolyScale);
    clip[3] = IntPoint(mbr.ll().x()*PolyScale,mbr.ur().y()*PolyScale);
    
    Clipper c;
    c.AddPolygon(subject, ptSubject);
    c.AddPolygon(clip, ptClip);
    Polygons solution;
    if (c.Execute(ctIntersection, solution))
    {
        for (unsigned int ii=0;ii<solution.size();ii++)
        {
            Polygon &outPoly = solution[ii];
            VectorRing outRing;
            for (unsigned jj=0;jj<outPoly.size();jj++)
            {
                IntPoint &outPt = outPoly[jj];
                outRing.push_back(Point2f(outPt.X/PolyScale,outPt.Y/PolyScale));
            }
            if (outRing.size() > 2)
                rets.push_back(outRing);
        }
        
        return true;
    }
    
    return false;
}

// Clip the given loop to the given grid (org and spacing)
// Return true on success and the new polygons in the rets
// Note: Not deeply efficient
bool ClipLoopToGrid(const WhirlyGlobe::VectorRing &ring,Point2f org,Point2f spacing,std::vector<WhirlyGlobe::VectorRing> &rets)
{
//    rets.push_back(ring);
//    return true;
    
    Mbr mbr(ring);
    int startRet = rets.size();
    
    int ll_ix = (int)std::floor((mbr.ll().x()-org.x())/spacing.x());
    int ll_iy = (int)std::floor((mbr.ll().y()-org.y())/spacing.y());
    int ur_ix = (int)std::ceil((mbr.ur().x()-org.x())/spacing.x());
    int ur_iy = (int)std::ceil((mbr.ur().y()-org.y())/spacing.y());
    
    // Clip in strips from left to right
    for (int ix=ll_ix;ix<=ur_ix;ix++)
    {
        Point2f l0(ix*spacing.x()+org.x(),mbr.ll().y());
        Point2f l1((ix+1)*spacing.x()+org.x(),mbr.ur().y());
        Mbr left(l0,l1);
        
        std::vector<VectorRing> leftStrip;
        ClipLoopToMbr(ring,left,leftStrip);
        
        // Now clip the left strip vertically
        for (int iy=ll_iy;iy<=ur_iy;iy++)
        {
            
            Point2f b0(mbr.ll().x(),iy*spacing.y()+org.y());
            Point2f b1(mbr.ur().x(),(iy+1)*spacing.y()+org.y());
            Mbr bot(b0,b1);
            for (unsigned int ic=0;ic<leftStrip.size();ic++)
                ClipLoopToMbr(leftStrip[ic], bot, rets);
        }
    }
    
    for (unsigned int ii=startRet;ii<rets.size();ii++)
    {
        VectorRing &theRing = rets[ii];
        std::reverse(theRing.begin(),theRing.end());
    }
    
    return true;
}