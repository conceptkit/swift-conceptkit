public typealias ConceptID = String
public typealias ConceptIDPath = [ConceptID]
public typealias ConceptGraph = [ConceptID: Concept]

public struct Concept: Codable {
    public struct Vector: Codable, Hashable {
        public enum Operator: String, Codable, Hashable, CaseIterable {
            case feed, add, diff, diffabs, multiply, multiplyint, divide, divideint
            case equalTo, notEqualTo, greaterThan, lessThan, lessThanOrEqualTo
        }
        
        let from: ConceptIDPath
        let target: ConceptIDPath
        let operand: ConceptIDPath?
        let operat0r: Operator
    }
    
    let id: ConceptID
    let vectors: [Vector]
}
