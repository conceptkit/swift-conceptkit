import Foundation

enum ConceptValue {
    case single(_ val: Double)
    case multi(_ val: ConceptValues)
}

public class ResolveCache {
    var resolvedConceptCache = [ConceptIDPath: [Int: ConceptValues]]()
    var resolvedConceptLastIndices = [ConceptIDPath: Int]()
    private var virtualVectorCache = [ConceptIDPath: [Vector]]()
    
    public init(resolvedConceptCache: [ConceptIDPath : [Int : ConceptValues]] = [ConceptIDPath: [Int: ConceptValues]](), resolvedConceptLastIndices: [ConceptIDPath : Int] = [ConceptIDPath: Int](), virtualVectorCache: [ConceptIDPath : [Vector]] = [ConceptIDPath: [Vector]]()) {
        self.resolvedConceptCache = resolvedConceptCache
        self.resolvedConceptLastIndices = resolvedConceptLastIndices
        self.virtualVectorCache = virtualVectorCache
    }
}

public class ConceptValuesInterface {
    var context: ConceptIDPath
    
    private var values: ConceptValues
    var dataSources: [ConceptID: ConceptValueFrames]
    
    public init(values: ConceptValues = .init(), dataSources: [ConceptID: ConceptValueFrames] = .init(), context: ConceptIDPath = []) {
        self.values = values
        self.dataSources = dataSources
        self.context = context
    }
}

public typealias TraceEvent = (context: ConceptIDPath, path: ConceptIDPath, clockTime: UInt64, success: Bool)
public class Trace {
    public var traceSoFar: [TraceEvent] = []
    
    public func didResolvePath(_ path: ConceptIDPath, context: ConceptIDPath) {
        traceSoFar.append(TraceEvent(context, path, DispatchTime.now().uptimeNanoseconds, true))
    }
    
    public func didFailPath(_ path: ConceptIDPath, context: ConceptIDPath) {
        traceSoFar.append(TraceEvent(context, path, DispatchTime.now().uptimeNanoseconds, false))
    }
}

public extension Concept {
    func resolve(values outputCV: ConceptValuesInterface = ConceptValuesInterface(), graph: ConceptGraph, isHardStop: inout Bool, cache: ResolveCache = .init(), trace: inout Trace) -> ConceptValues? {
        var allInputs = outputCV.localValues
        let specifiedIndex: Int? = allInputs[["Index"]] != nil ? Int(allInputs[["Index"]]!) : nil
        let requiredIndex = Int(allInputs[["Index"]] ?? Double(0))
        var currentIndex = Int(0)
        var virtualVectors = [Vector]()
        
        if let specifiedIndex = specifiedIndex, let (lastBuilt, lastIndex) = cache.getLastBuilt(path: outputCV.context, requiredIndex: specifiedIndex), let vVectors = cache.virtualVectorsFor(path: outputCV.context) {
            // Kick off the progressive resolution from the last resolved
            allInputs.addAll(lastBuilt)
            currentIndex = lastIndex+1
            virtualVectors = vVectors
        }
        
        // Return failed vectors if any
        func buildVectorList(_ vectorsToProcess: [Vector], built: inout Set<Vector>, virtualVectors: inout [Vector], externalLinkVectors: [ConceptIDPath: Vector], isSkippingSelfReferential: Bool) -> [ConceptIDPath] {
            func buildVector(_ vector: Vector, nextVector: Vector?) -> [ConceptIDPath] {
                guard let fromValue = outputCV.getActiveValue(vector.from, graph: graph, virtualVectors: &virtualVectors, externalLinkVectors: externalLinkVectors, built: &built, cache: cache, isHardStop: &isHardStop, trace: &trace) else {
                    trace.didFailPath(vector.from, context: outputCV.context + [self.id])
                    return [vector.from]
                }
                trace.didResolvePath(vector.from, context: outputCV.context + [self.id])
                var valueToCopy = fromValue
                let operand = vector.operand
                if !operand.isEmpty {
                    guard let operandValue = outputCV.getActiveValue(operand, graph: graph, virtualVectors: &virtualVectors, externalLinkVectors: externalLinkVectors, built: &built, cache: cache, isHardStop: &isHardStop, trace: &trace) else {
                        trace.didFailPath(operand, context: outputCV.context + [self.id])
                        return [operand]
                    }
                    trace.didResolvePath(operand, context: outputCV.context + [self.id])
                    guard let merged = fromValue.runVectorOperator(otherValue: operandValue, otherPath: operand, operat0r: vector.operat0r) else {
                        if (vector.target.isEmpty) {
                            return [vector.from, operand]
                        }
                        return []
                    }
                    valueToCopy = merged
                }
                if (!vector.target.isEmpty && !(vector.isSelfReferential() && vector.operat0r == .feed)) {
                    let isExclusion = vector.target.first != nil && vector.target.first!.isExclusion()
                    let cleanedTarget = vector.target.map { $0.stripExclusion() }
                    outputCV.copyVal(valueToCopy, toPath: cleanedTarget, graph: graph)
                    if vector.target.first != nextVector?.target.first {
                        guard outputCV.getActiveValue(cleanedTarget, graph: graph, isExclusion: isExclusion, virtualVectors: &virtualVectors, externalLinkVectors: externalLinkVectors, built: &built, cache: cache, isHardStop: &isHardStop, trace: &trace) != nil else {
                            if isExclusion {
                                trace.didResolvePath(cleanedTarget, context: outputCV.context + [self.id])
                                // success
                                return []
                            }
                            // failure
                            trace.didFailPath(cleanedTarget, context: outputCV.context + [self.id])
                            return [vector.target]
                        }
                        if isExclusion {
                            outputCV.cleanEverythingUnder(path: cleanedTarget)
                            // failure
                            trace.didFailPath(cleanedTarget, context: outputCV.context + [self.id])
                            return [vector.target]
                        }
                        trace.didResolvePath(cleanedTarget, context: outputCV.context + [self.id])
                    }
                }
                
                // success
                return []
            }
            
            func isSkipped(_ vector: Vector) -> Bool {
                return built.contains(vector) || (isSkippingSelfReferential && vector.isSelfReferential())
            }
            
            for v in 0..<vectorsToProcess.count {
                let vector = vectorsToProcess[v]
                if isSkipped(vector) {
                    continue;
                }
                let nextVector = (v < vectorsToProcess.count - 1 ? Array(vectorsToProcess[(v+1)...]) : []).filter { !isSkipped($0) }.first
                let failed = buildVector(vector, nextVector: nextVector)
                if failed.isEmpty {
                    built.insert(vector)
                } else {
                    return failed
                }
            }
            
            let remaindingVectors = vectorsToProcess.filter { !built.contains($0) }
            for vector in remaindingVectors {
                let failed = buildVector(vector, nextVector: nil)
                if failed.isEmpty {
                    built.insert(vector)
                } else {
                    return failed
                }
            }
            
            // success
            return []
        }
        
        func firstCycleVectorUpstream(_ inclusion: ConceptIDPath) -> Vector? {
            func firstVirtualVector<V: Any>(_ path: ConceptIDPath, dict: [ConceptID: V]) -> Vector? {
                guard let pathEndingInKey = dict.linkedKey(inPath: path) else { return nil }
                let indexInclusion = pathEndingInKey + ["Index"]
                //IMPORTANT! complexity issue
                return virtualVectors.first(where: { v in
                    v.target == indexInclusion
                })
            }
            
            let upstream = vectors.vectorsUpstreamOf(inclusion)
            for uVector in upstream {
                if !uVector.from.isEmpty, let virtual = firstVirtualVector(uVector.from, dict: graph) {
                    return virtual
                } else if uVector.isSelfReferential() {
                    return uVector
                } else if !uVector.operand.isEmpty, let virtual = firstVirtualVector(uVector.operand, dict: graph) {
                    return virtual
                }
            }
            return firstVirtualVector(inclusion, dict: graph) ?? firstVirtualVector(inclusion, dict: outputCV.dataSources)
        }
        
        let cycleVectors = self.vectors.filter { $0.isSelfReferential() }
        var externalLinkedCycleVectors = [ConceptIDPath: Vector]()
        for cycleVector in cycleVectors {
            guard let linked = graph.linkedKey(inPath: cycleVector.target) ?? outputCV.dataSources.linkedKey(inPath: cycleVector.target) else { continue }
            externalLinkedCycleVectors[linked] = cycleVector
        }
        
        
        func removeVectorPlusDownstream(_ vector: Vector, builtSet: inout Set<Vector>) {
            builtSet.remove(vector)
            var empty = Set<Vector>()
            builtSet.subtract(vectors.vectorsDownstreamOf(vector.target, soFarSet: &empty))
        }
        
        let roots = Set(self.vectors.getRootInclusions(external: outputCV.dataSources))
        let initialRootCVs = allInputs.filter { roots.contains($0.key) }
        
        var builtSet = Set<Vector>()
        var isSkippingSelfReferential = true
        while (currentIndex <= requiredIndex) {
            let failedVirtuals = buildVectorList(virtualVectors, built: &builtSet, virtualVectors: &virtualVectors, externalLinkVectors: externalLinkedCycleVectors, isSkippingSelfReferential: false)
            if !failedVirtuals.isEmpty {
                // failed
                return nil
            }
            let failedPaths = buildVectorList(self.vectors.calcBuildOrder(), built: &builtSet, virtualVectors: &virtualVectors, externalLinkVectors: externalLinkedCycleVectors, isSkippingSelfReferential: isSkippingSelfReferential)
            if !failedPaths.isEmpty {
                if isHardStop {
                    return nil
                }
                var hadRelatedCycles = false
                // do not run virtual vectors for retry unless specifically downstream
                builtSet.formUnion(virtualVectors)
                for fail in failedPaths {
                    if let relatedCycle = firstCycleVectorUpstream(fail) {
                        removeVectorPlusDownstream(relatedCycle, builtSet: &builtSet)
                        hadRelatedCycles = true
                    }
                }
                
                if hadRelatedCycles {
                    let afterRootCVs = outputCV.localValues.filter { roots.contains($0.key) }
                    if (initialRootCVs != afterRootCVs) {
                        // if roots change, all cycle vectors and downstream should also
                        for cycleVector in cycleVectors {
                            removeVectorPlusDownstream(cycleVector, builtSet: &builtSet)
                        }
                    }
                    // retry
                    isSkippingSelfReferential = false
                    continue
                } else {
                    return nil
                }
            } else {
                // reset for next index
                builtSet.removeAll()
                isSkippingSelfReferential = true
            }
            
            // only cache if index mode = aka move this up a level?
            cache.cacheResolutionSuccess(path: outputCV.context, index: currentIndex, outputs: outputCV.localValues, virtualVectors: virtualVectors)
            currentIndex += 1
        }
        
        return outputCV.localValues
    }
}

fileprivate extension ResolveCache {
    func virtualVectorsFor(path: ConceptIDPath) -> [Vector]? {
        if let vectors = self.virtualVectorCache[path], vectors.count > 0 {
            return vectors
        }
        return nil
    }
    
    func cacheResolutionSuccess(path: ConceptIDPath, index: Int, outputs: ConceptValues, virtualVectors: [Vector]) {
        var conceptResolvedCache = self.resolvedConceptCache[path] ?? .init()
        conceptResolvedCache[index] = outputs.union([["Index"]: Double(index)])
        self.resolvedConceptCache[path] = conceptResolvedCache
        if !virtualVectors.isEmpty {
            self.resolvedConceptLastIndices[path] = index
            self.virtualVectorCache[path] = virtualVectors
            
        }
    }
    
    func getLastBuilt(path: ConceptIDPath, requiredIndex: Int) -> (ConceptValues, Int)? {
        guard let lastIndex = self.resolvedConceptLastIndices[path] else { return nil }
        guard requiredIndex > lastIndex else { return nil}
        guard let lastOutputs = self.resolvedConceptCache[path]?[lastIndex] else { return nil }
        return (lastOutputs, lastIndex)
    }
}

fileprivate extension ConceptValuesInterface {
    var localValues: ConceptValues {
        values.filterForContext(context)
    }
    
    subscript(path: ConceptIDPath) -> Double? {
        get {
            return values[context + path]
        }
        set {
            values[context + path] = newValue
        }
    }
    
    func findLocalValuesWithPrefix(_ path: ConceptIDPath) -> ConceptValues {
        let fullContext = context + path;
        return values.filterForContext(fullContext)
    }
    
    func ingestLocalValues(_ newValues: ConceptValues, additionalLocalContext: ConceptIDPath) {
        for (key, value) in newValues {
            self[additionalLocalContext + key] = value
        }
    }
    
    func cleanEverythingUnder(path: ConceptIDPath) {
        for key in values.keys where key.starts(with: path) {
            self.values[key] = nil
        }
    }
    
    func appendLocalContext(_ localPath: ConceptIDPath) -> ConceptValuesInterface {
        return .init(values: values, dataSources: dataSources, context: context + localPath)
    }
    
    func copyVal(_ val: ConceptValue, toPath path: ConceptIDPath, graph: ConceptGraph) {
        if let pathEndingInDataSource = dataSources.linkedKey(inPath: path), path.last != "Index" {
            // DATA WRITE
            var dataSource = dataSources[pathEndingInDataSource.last!]!
            let indexOptional = self[pathEndingInDataSource + ["Index"]]
            let index = indexOptional ?? 0
            switch val {
            case .multi(let cv):
                for (path, value) in cv {
                    let subpath = Array(path[(pathEndingInDataSource.count)...])
                    guard subpath.count > 0 else { return }
                    dataSource[Int(floor(index))][subpath] = value
                }
            case .single(let value):
                dataSource[Int(floor(index))][path] = value
            }
        }
        
        switch val {
        case .multi(let cv):
            for (key, value) in cv {
                self[key] = value
            }
        case .single(let value):
            self[path] = value
        }
    }
    
    func getActiveValue(_ path: ConceptIDPath, graph: ConceptGraph, isExclusion: Bool = false, virtualVectors: inout [Vector], externalLinkVectors: [ConceptIDPath: Vector], built: inout Set<Vector>, cache: ResolveCache, isHardStop: inout Bool, trace: inout Trace) -> ConceptValue? {
        if let value = path.numberValue {
            return .single(value)
        }
        
        func addVirtualIndexIncrementVector(_ indexPath: ConceptIDPath) {
            let virtualVector = Vector(from: indexPath, target: indexPath, operand: ["1"], operat0r: .add)
            ///// performance issue
            let containsAlready = virtualVectors.contains { v in
                v.toCode() == virtualVector.toCode()
            }
            
            if (!containsAlready) {
                virtualVectors.append(virtualVector)
                built.insert(virtualVector)
                self[indexPath] = 0
            }
        }
        
        var soFar: ConceptIDPath = []
        for part in path {
            if let innerConcept = graph[part] {
                let pathInclConcept = soFar + [part]
                let indexPath = pathInclConcept + ["Index"]
                
                let allInputs = appendLocalContext(pathInclConcept)
                // no inputs is an implied first or 0th index
                let index: Double? = self[indexPath] ?? (allInputs.localValues.isEmpty ? 0.0 : nil)
                //let roots = Set(innerConcept.vectors.getRootInclusions(external: allInputs.dataSources))
                //let suppliedRoots = allInputs.filter { roots.contains($0.key) }
                
                if let index = index, let preBuilt: ConceptValues = cache.resolvedConceptCache[allInputs.context]?[Int(index)] {
                    ingestLocalValues(preBuilt, additionalLocalContext: pathInclConcept)
                } else {
                    var isLocalFatal = false;
                    guard let builtValues = innerConcept.resolve(values: allInputs, graph: graph, isHardStop: &isLocalFatal, cache: cache, trace: &trace) else {
                        if isLocalFatal {
                            isHardStop = true
                        }
                        return nil
                    }
                    if index != nil && !isExclusion && externalLinkVectors[pathInclConcept] == nil {
                        addVirtualIndexIncrementVector(indexPath)
                    }
                    ingestLocalValues(builtValues, additionalLocalContext: pathInclConcept)
                }
                break
            } else if let dataSource = dataSources[part] {
                let pathEndingInDataSource = soFar + [part]
                let indexPath = pathEndingInDataSource + ["Index"]
                if path == indexPath && externalLinkVectors[pathEndingInDataSource] == nil  {
                    guard let value = self[indexPath] else {
                        return nil
                    }
                    return .single(value)
                }
                // DATA READ
                let subpath = Array(path[(pathEndingInDataSource.count)...])
                let index = self[indexPath] ?? 0
                if self[indexPath] == nil && !isExclusion {
                    addVirtualIndexIncrementVector(indexPath)
                }
                if Int(floor(index)) >= dataSource.count {
                    isHardStop = true
                    return nil
                }

                let dataConceptValues = dataSource[Int(floor(index))]
                if (subpath.count > 0) {
                    guard let value = dataConceptValues[subpath] else {
                        return nil
                    }
                    self[path] = value
                    return .single(value)
                } else {
                    ingestLocalValues(dataConceptValues, additionalLocalContext: path)
                    return .multi(dataConceptValues)
                }
            }
            soFar.append(part)
        }
        
        let returnValues = findLocalValuesWithPrefix(path);
        guard !returnValues.isEmpty, path.last != nil else { return nil }
        
        if let value = self[path], returnValues.count == 1 {
            return .single(value)
        } else {
            return .multi(returnValues)
        }
    }
}

fileprivate extension ConceptValue {
    func runVectorOperator(otherValue: ConceptValue, otherPath: ConceptIDPath, operat0r: Vector.Operator) -> ConceptValue? {
        switch self {
        case .single(let val):
            switch otherValue {
            case .single(let otherVal):
                guard let result = operat0r.calc(val, operandValue: otherVal) else {
                    return nil
                }
                return .single(result)
            case .multi(let cv):
                return .multi(cv.mapValues({ otherVal in
                    operat0r.calc(val, operandValue: otherVal)!
                }))
            }
        case .multi(let cv):
            switch otherValue {
            case .single(let otherVal):
                return .multi(cv.union([otherPath : otherVal]))
            case .multi(let otherCV):
                return .multi(cv.union(otherCV))
            }
        }
    }
}

public extension Dictionary where Key == ConceptID {
    func linkedKey(inPath path: ConceptIDPath) -> ConceptIDPath? {
        var soFar: ConceptIDPath = []
        for part in path {
            if self[part.stripExclusion()] != nil {
                soFar.append(part)
                return soFar
            }
            soFar.append(part)
        }
        return nil
    }
}

fileprivate extension ConceptValues {
    func filterForContext(_ context: ConceptIDPath) -> ConceptValues {
        if context.count > 0 {
            return self.reduce(into: ConceptValues()) { result, element in
                guard element.key.starts(with: context) else { return }
                result[Array(element.key.dropFirst(context.count))] = element.value
            }
        }
        return self
    }
}
