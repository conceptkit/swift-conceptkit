import Foundation

public class ModificationScope {
    var id: ConceptID
    var graph: ConceptGraph
    
    init(_ id: ConceptID, graph: ConceptGraph) {
        self.id = id
        self.graph = graph
    }
}

extension ConceptGraph {
    public mutating func modify(
        _ id: ConceptID,
        vectors: [Vector]? = nil,
        inclusions: Set<ConceptIDPath>? = nil,
        values: ConceptValues? = nil
    ) -> ModificationScope {
        let modified: Concept = {
            if let existing = self[id] {
                return Concept(id: id, vectors: vectors ?? existing.vectors)
            } else {
                return Concept(id: id, vectors: vectors ?? .init())
            }
        }()
        self[id] = modified
        return .init(id, graph: self)
    }
}

extension Concept {
    public init(_
        id: ConceptID,
        vectors: [Vector] = .init(),
        values: ConceptValues = .init()
    ) {
        self.id = id
        self.vectors = vectors
    }
}

extension ModificationScope {
    public func addValueFeed(_ value: Double, forInclusion path: ConceptIDPath) -> ModificationScope {
        let concept = graph[id] ?? Concept(id)
        
        func toString(_ number: Double) -> String {
            if number == Double(Int(number)) {
                return "\(Int(number))"
            } else {
                return "\(number)"
            }
        }

        let vectorFeedValue = Vector(from: [toString(value)], target: path, operand: nil, operat0r: .feed)
        graph[id] = Concept(id: id, vectors: concept.vectors + [vectorFeedValue])
        return .init(id, graph: graph)
    }
    
    public func addVector( _ vector: Vector) -> ModificationScope {
        let concept = graph[id] ?? Concept(id)
        
        var vectors = concept.vectors
        vectors.append(vector)
        
        graph[id] = Concept(id: id, vectors: vectors)
        return ModificationScope(id, graph: graph)
    }
}
