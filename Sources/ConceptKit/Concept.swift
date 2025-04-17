public typealias ConceptID = String
public typealias ConceptIDPath = [ConceptID]
public typealias ConceptGraph = [ConceptID: Concept]

public struct Concept: Codable {
    public let id: ConceptID
    public let vectors: [Vector]
}

public struct Vector: Codable, Hashable {
    public enum Operator: String, Codable, Hashable, CaseIterable {
        case feed, add, diff, diffabs, multiply, multiplyint, divide, divideint
        case equalTo, notEqualTo, greaterThan, lessThan, lessThanOrEqualTo
    }
    
    public let from: ConceptIDPath
    public let target: ConceptIDPath
    public let operand: ConceptIDPath?
    public let operat0r: Operator
}
