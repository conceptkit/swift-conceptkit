import Foundation

public extension ConceptGraph {
    static func fromCode(_ string: String, error: inout String?) -> ConceptGraph? {
        guard let tokeniser = ConceptStringTokenizer(string: string) else { return nil }
        let grouper = TokenGrouper(tokeniser, groupTypes: ConceptTokenGroup.allCases)
        
        var graph = ConceptGraph()
        var scope: ModificationScope?
        
        var currentIDPath: ConceptIDPath = .init()
        var currentLHS: ConceptIDPath?
        var currentOperator: Vector.Operator?
        var currentFeedOperand: ConceptIDPath = .init()
        
        func reset() {
            currentLHS = nil
            currentIDPath = .init()
            currentFeedOperand = .init()
            currentOperator = nil
        }
        
        func tryCloseOutVectorOrCondition() {
            guard currentLHS != nil || !currentFeedOperand.isEmpty || currentOperator != nil || !currentIDPath.isEmpty else { return }

            if currentFeedOperand.isEmpty, let currentOperator = currentOperator, currentOperator != .feed, let currentLHS = currentLHS, !currentIDPath.isEmpty {
                // probably a condition?
                scope = scope?.addVector(
                    Vector(
                        from: currentLHS,
                        target: [],
                        operand: currentIDPath,
                        operat0r: currentOperator)
                )
                reset()
                return
            }
            
            let lhs = currentLHS ?? currentIDPath
            let op = currentOperator ?? .feed
            scope = scope?.addVector(
                Vector(
                    from: lhs,
                    target: currentIDPath,
                    operand: currentFeedOperand,
                    operat0r: op)
            )
            reset()
        }
        
        while let group = grouper.next() {
            switch group.type {
            case .conceptID:
                // add to existing
                for token in group.tokens {
                    addPieceToConcept(token.string, path: &currentIDPath)
                }
                
                if let op = currentOperator, op.isSignIndicator, currentLHS == nil, currentIDPath.count == 1,
                   let numberString = currentIDPath.first, Double(numberString) != nil {
                    // attach it as a sign in front
                    currentIDPath.removeAll()
                    currentIDPath = ["\(op.toCode())\(numberString)"]
                    
                    currentOperator = nil
                }
            case .possibleConceptSegmenter:
                guard !currentIDPath.isEmpty else {
                    print("❓Expeced label prior to concept segmenter repeated char (3 or more)")
                    continue
                }
                
                if let modScope = scope {
                    graph = modScope.graph
                }
                scope = .init(currentIDPath.toCode(), graph: graph)
                reset()
                continue
            case .possibleOperator:
                let joined = group.tokens.map { $0.string }.joined()
                
                if let vectorOp = joined.toVectorOperator() {
                    currentOperator = vectorOp
                    if !currentIDPath.isEmpty {
                        currentLHS = currentIDPath
                        currentIDPath = .init()
                    }
                } else if joined.isExclusion() {
                    currentIDPath.append(joined)
                } else {
                    print("🤨 Unknown operator type token: `\(joined)`")
                }
            case .none:
                if (group.tokens.map { $0.string }) ==  ["\n"] {
                    tryCloseOutVectorOrCondition()
                    // keep going
                    continue
                }
                let joined = group.tokens.map { $0.string }.joined()
                if joined.trimmingCharacters(in: .whitespaces) != "" {
                    print("⏭ skipping: `\(joined)`")
                }
            case .feedOperator:
                if currentLHS != nil, !currentIDPath.isEmpty {
                    // populate operand
                    currentFeedOperand = currentIDPath
                    currentIDPath = .init()
                }
                if currentFeedOperand.isEmpty {
                    currentOperator = .feed
                    if !currentIDPath.isEmpty {
                        currentLHS = currentIDPath
                    }
                    currentIDPath = .init()
                }
                continue
            }
        }
        tryCloseOutVectorOrCondition()
 
        return scope?.graph ?? graph
    }
    
    static func addPieceToConcept(_ concept: String, path: inout ConceptIDPath) {
        guard let last = path.last, !concept.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: ".") else {
            // new concept
            if Double(concept) != nil {
                path.append(concept)
            } else {
                let split = concept.split(separator: ".").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                path.append(contentsOf: split)
            }
            return
        }
        
        let split = concept.split(separator: ".").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let firstNew = split.first else { return }
        _ = path.popLast()
        
        let newLast = last + " " + firstNew
        path.append(newLast)
        
        for i in 1..<split.count {
            path.append(split[i])
        }
    }
}

public class ModificationScope {
    var id: ConceptID
    var graph: ConceptGraph
    
    init(_ id: ConceptID, graph: ConceptGraph) {
        self.id = id
        self.graph = graph
    }
}

fileprivate extension Concept {
    init(_
        id: ConceptID,
        vectors: [Vector] = .init(),
        values: ConceptValues = .init()
    ) {
        self.id = id
        self.vectors = vectors
    }
}

public extension ModificationScope {
    func addValueFeed(_ value: Double, forInclusion path: ConceptIDPath) -> ModificationScope {
        let concept = graph[id] ?? Concept(id)
        
        func toString(_ number: Double) -> String {
            if number == Double(Int(number)) {
                return "\(Int(number))"
            } else {
                return "\(number)"
            }
        }

        let vectorFeedValue = Vector(from: [toString(value)], target: path, operand: [], operat0r: .feed)
        graph[id] = Concept(id: id, vectors: concept.vectors + [vectorFeedValue])
        return .init(id, graph: graph)
    }
    
    func addVector( _ vector: Vector) -> ModificationScope {
        let concept = graph[id] ?? Concept(id)
        
        var vectors = concept.vectors
        vectors.append(vector)
        
        graph[id] = Concept(id: id, vectors: vectors)
        return ModificationScope(id, graph: graph)
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

extension Vector {
    static func fromCode(_ string: String, error: inout String?) -> Vector? {
        return nil
    }
}

extension Vector.Operator {
    var isSignIndicator: Bool {
        switch self {
        case .add:
            return true
        case .diff:
            return true
        default:
            return false
        }
    }
}

extension String {
    func toVectorOperator() -> Vector.Operator? {
        if self == "->" || self == Vector.Operator.feed.toCode()  {
            return .feed
        } else if self == Vector.Operator.add.toCode() {
            return .add
        } else if self == Vector.Operator.diff.toCode() {
            return .diff
        } else if self == Vector.Operator.diffabs.toCode() {
            return .diffabs
        } else if self == Vector.Operator.divide.toCode() {
            return .divide
        } else if self == Vector.Operator.divideint.toCode() {
            return .divideint
        } else if self == Vector.Operator.multiply.toCode() {
            return .multiply
        } else if self == Vector.Operator.multiplyint.toCode() {
            return .multiplyint
        } else if self == Vector.Operator.equalTo.toCode() {
            return .equalTo
        } else if self == Vector.Operator.notEqualTo.toCode() {
            return .notEqualTo
        } else if self == Vector.Operator.greaterThan.toCode() {
            return .greaterThan
        } else if self == Vector.Operator.lessThan.toCode() {
            return .lessThan
        } else if self == Vector.Operator.lessThanOrEqualTo.toCode() {
            return .lessThanOrEqualTo
        }
        return nil
    }
}
