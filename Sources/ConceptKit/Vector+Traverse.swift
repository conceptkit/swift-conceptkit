import Foundation

public extension Array where Element == Vector {
    
    // Calculates the build order based on the dependancies within.
    func calcBuildOrder() -> [Vector] {
        let top = self.getLeafInclusions()
        var seen = Set<Vector>()
        var vectorsToBuild: [Vector] = []
        for leaf in top {
            let upstream = self.vectorsUpstreamOf(leaf).sorted { v1, v2 in
                if !v1.isSelfReferential() && v2.isSelfReferential() {
                    return false
                }
                return true
            }
            for up in upstream where !seen.contains(up) {
                seen.insert(up)
                vectorsToBuild.append(up)
            }
        }
        return vectorsToBuild + (self.filter { !seen.contains($0) })
    }
    
    // Root inclusions are those which feed others but are never fed.
    // Number feeds don't take away root status.
    // Includes virtual concepts i.e. data-source/concpt-resolve cache index
    func getRootInclusions<V: Any>(external: [ConceptID: V]) -> [ConceptIDPath] {
        var excludedTargets = Set<ConceptIDPath>()
        var potentialTops = [ConceptIDPath]()
        for vector in self where !excludedTargets.contains(vector.target) {
            let fromNumberVal = vector.from.numberValue
            if !vector.from.isEmpty, fromNumberVal == nil {
                potentialTops.append(vector.from)
            }
            if !vector.operand.isEmpty, vector.operand.numberValue == nil {
                potentialTops.append(vector.operand)
            }
            
            if fromNumberVal != nil, vector.operand.isEmpty, !vector.target.isEmpty {
                potentialTops.append(vector.target);
            } else if (vector.from != vector.target && vector.operand != vector.target) {
                excludedTargets.insert(vector.target)
            }
        }

        var included = Set<ConceptIDPath>()
        var seenLinks = Set<ConceptIDPath>()
        return potentialTops.compactMap {
            guard !excludedTargets.contains($0) && !included.contains($0) else { return nil }
            if let link = external.linkedKey(inPath: $0) {
                if !seenLinks.contains(link) {
                    seenLinks.insert(link)
                    let virtual = link + ["Index"]
                    included.insert(virtual)
                    return virtual
                } else {
                    return nil
                }
            } else {
                return $0
            }
        }
    }
    
    // Inclusions which are fed but never fed to another.
    func getLeafInclusions() -> [ConceptIDPath] {
        var excludedTargets = Set<ConceptIDPath>()
        var potentialLeaves = [ConceptIDPath]()
        func exclude(_ path: ConceptIDPath?) {
            guard let path = path else { return }
            excludedTargets.insert(path)
        }
        
        for vector in self where !excludedTargets.contains(vector.target) {
            guard !vector.target.isEmpty else {
                continue
            }
            potentialLeaves.append(vector.target)
            
            if vector.from != vector.target {
                exclude(vector.from)
            }
            if vector.operand != vector.target {
                exclude(vector.operand)
            }
        }

        var included = Set<ConceptIDPath>()
        return potentialLeaves.filter {
            guard !excludedTargets.contains($0) && !included.contains($0) else { return false }
            included.insert($0)
            return true
        }
    }
    
    // Returns all vectors feeding this inclusion `path`.
    func vectorsUpstreamOf(_ path: ConceptIDPath) -> [Vector] {
        func _vectorsUpstreamOf(_ path: ConceptIDPath, seen: inout Set<Vector>) -> [Vector] {
            var soFar: [Vector] = []
            // put self referential ones first since this is from an upstream (backwards to downstream) perspective
            let nextVectors = self.filter { return $0.target.first == path.first }.sorted { v1, v2 in
                if !v1.isSelfReferential() && v2.isSelfReferential() {
                    return false
                }
                return true
            }
            for vector in nextVectors where !seen.contains(vector) {
                soFar.append(vector)
                seen.insert(vector)
                soFar += _vectorsUpstreamOf(vector.from, seen: &seen)
                if !vector.operand.isEmpty {
                    soFar += _vectorsUpstreamOf(vector.operand, seen: &seen)
                }
            }
            return soFar
        }
        
        var seen = Set<Vector>()
        return _vectorsUpstreamOf(path, seen: &seen)
    }
    
    // Returns all vectors downstream of this inclusion `path`.
    func vectorsDownstreamOf(_ path: ConceptIDPath, soFarSet: inout Set<Vector>) -> [Vector] {
        var soFar: [Vector] = []
        let nextVectors = self.filter {
            $0.from.first == path.first || $0.operand.first == path.first
        }
        for vector in nextVectors where !soFarSet.contains(vector) {
            soFar.append(vector)
            soFarSet.insert(vector)
            soFar += vectorsDownstreamOf(path, soFarSet: &soFarSet)
        }
        return soFar
    }
}

public extension Vector {
    func isSelfReferential() -> Bool {
        guard self.operat0r != .feed, !target.isEmpty else { return false }
        return from == target || operand == target
    }
}
