#!/bin/bash
xcodebuild -target WhirlyGlobeLib -configuration Debug -sdk iphonesimulator
xcodebuild -target WhirlyGlobeLib -configuration Release -sdk iphonesimulator
xcodebuild -target WhirlyGlobeLib -configuration Debug -sdk iphoneos
xcodebuild -target WhirlyGlobeLib -configuration Release -sdk iphoneos
lipo -create build/Debug-iphoneos/libWhirlyGlobeLib.a build/Debug-iphonesimulator/libWhirlyGlobeLib.a -output ./lib/libWhirlyGlobeLibd.a
lipo -create build/Release-iphoneos/libWhirlyGlobeLib.a build/Release-iphonesimulator/libWhirlyGlobeLib.a -output ./lib/libWhirlyGlobeLib.a
