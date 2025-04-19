public typealias ConceptID = String
public typealias ConceptIDPath = [ConceptID]

public struct Concept {
    public let id: ConceptID
    public let vectors: [Vector]
}

public struct Vector: Hashable {
    public enum Operator: String {
        case feed, add, diff, diffabs, multiply, multiplyint, divide, divideint
        case equalTo, notEqualTo, greaterThan, lessThan, lessThanOrEqualTo
    }
    
    public let from: ConceptIDPath
    public let target: ConceptIDPath
    public let operand: ConceptIDPath?
    public let operat0r: Operator
}

public typealias ConceptGraph = [ConceptID: Concept]
