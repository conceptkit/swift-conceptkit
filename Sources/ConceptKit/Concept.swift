public typealias ConceptID = String
public typealias ConceptIDPath = [ConceptID]

public struct Concept {
    let id: ConceptID
    let vectors: [Vector]
}

public struct Vector: Hashable {
    public enum Operator: String {
        case feed, add, diff, diffabs, multiply, multiplyint, divide, divideint
        case equalTo, notEqualTo, greaterThan, lessThan, lessThanOrEqualTo
    }
    
    let from: ConceptIDPath
    let target: ConceptIDPath
    let operand: ConceptIDPath
    let operat0r: Operator
}

public typealias ConceptGraph = [ConceptID: Concept]
