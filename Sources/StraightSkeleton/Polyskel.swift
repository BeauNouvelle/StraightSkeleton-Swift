//
//  Polyskel.swift
//  Polyskel-Swift
//
//  Created by Andy Geers on 22/11/2019.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/andygeers/Polyskel-Swift
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Euclid
import OSLog

public class Subtree {
    public var source : Vector
    public var height : Double
    public var sinks : [Vector]
    public var edges : [LineSegment]
    
    init(source : Vector, height : Double, sinks : [Vector], edges: [LineSegment]) {
        self.source = source
        self.height = height
        self.sinks = sinks
        self.edges = edges
    }
}

public class Polyskel {
    
    public static var debugLog : Bool = false
    
    /**
       Compute the straight skeleton of a polygon.
       The polygon should be given as a list of vertices in counter-clockwise order.
       Holes is a list of the contours of the holes, the vertices of which should be in clockwise order.
       Returns the straight skeleton as a list of "subtrees", which are in the form of (source, height, sinks),
       where source is the highest points, height is its height, and sinks are the point connected to the source.
    */
    public static func skeletonize(polygon: Euclid.Polygon, holes: [Euclid.Polygon]?) -> StraightSkeleton {
        let contourHoles: [Contour]?
        if (holes != nil) {
            contourHoles = holes!.map { Contour($0) }
        } else {
            contourHoles = nil
        }
        return skeletonize(contour: Contour(polygon), holes: contourHoles)
    }
    
    /**
       Compute the straight skeleton of a polygon.
       Returns the straight skeleton as a list of "subtrees", which are in the form of (source, height, sinks),
       where source is the highest points, height is its height, and sinks are the point connected to the source.
    */
    public static func skeletonize(contour: Contour, holes: [Contour]?) -> StraightSkeleton {
    
        let slav = SLAV(contour: contour, holes: holes)
        var output : [Subtree] = [];
        var prioque = PriorityQueue<SkeletonEvent>(sort: { (e1 : SkeletonEvent, e2 : SkeletonEvent) in
            return e1.distance < e2.distance
        })

        for lav in slav {
            for vertex in lav {
                let v = vertex.nextEvent()
                if (v != nil) {
                    prioque.enqueue(v!)
                }
            }
        }

        while !(prioque.isEmpty || slav.isEmpty) {
            if (Polyskel.debugLog) { os_log("SLAV is %@", slav.map { $0 }) }
            let i = prioque.dequeue()!            
            
            if (!i.isValid()) {
                if (Polyskel.debugLog) { os_log("%.2f Discarded outdated edge event %@", i.distance, i.description) }
                continue
            }
            
            let (arc, events) = slav.handleEvent(i)
            
            prioque.enqueueAll(events)

            if (arc != nil) {
                output.append(arc!)
            }
        }
        return StraightSkeleton(contour: contour, holes: holes, subtrees: output)
    }
        
}
