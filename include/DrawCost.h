/*
 *  DrawCost.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 7/11/11.
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

#import <Foundation/Foundation.h>

/* Draw Cost
    A simple representation of what something costs to draw.
    The values might be fractions, meaning we're sharing resources.
 */
@interface DrawCost : NSObject 
{
    float numDrawables;  // How many drawables we created for the thing
    float numTextures;   // Number of textures we created for it
}

@property (nonatomic,assign) float numDrawables;
@property (nonatomic,assign) float numTextures;

@end
