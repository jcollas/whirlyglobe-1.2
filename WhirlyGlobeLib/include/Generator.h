/*
 *  DrawGenerator.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/10/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
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

#import <UIKit/UIKit.h>
#import <map>
#import <list>
#import "Texture.h"
#import "Drawable.h" 
#import "GlobeView.h"

@class RendererFrameInfo;

namespace WhirlyGlobe 
{
    
class Generator : public Identifiable
{
public:
    Generator() { }
    virtual ~Generator() { }
    
    // Generate a list of drawables to draw
    virtual void generateDrawables(RendererFrameInfo *frameInfo,std::vector<Drawable *> &drawables) { };
};
    
class GeneratorChangeRequest : public ChangeRequest
{
public:
    GeneratorChangeRequest(SimpleIdentity genId) : genId(genId) { }
    GeneratorChangeRequest() { }
    
    void execute(GlobeScene *scene,WhirlyGlobeView *view);
    
    virtual void execute2(GlobeScene *scene,Generator *drawGen) = 0;
    
protected:
    SimpleIdentity genId;
};
    

}
