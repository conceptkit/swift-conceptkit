import Foundation

public typealias ConceptValues = [ConceptIDPath: Double]

fileprivate let ExclusionPrefix = "!"
public extension String {
    func isExclusion() -> Bool {
        return hasPrefix(ExclusionPrefix)
    }
    
    func stripExclusion() -> String {
        guard isExclusion() else { return self }
        return String(dropFirst()).trim()
    }
}

public protocol ConceptValueFrames {
    subscript(_ index: Int) -> ConceptValues { get set }
    var count: Int { get }
    func commitEdits() -> Bool
}

extension ConceptIDPath {
    var numberValue: Double? {
        guard self.count == 1, let value = Double(self.first!) else {
            return nil
        }
        return value
    }
}

public extension Concept.Vector.Operator {
    func calc(_ input: Double, operandValue: Double?) -> Double? {
        guard let operandValue = operandValue else { return input }
        
        switch self {
        case .divide:
            return input/operandValue
        case .divideint:
            return floor(input/operandValue)
        case .multiply:
            return input*operandValue
        case .multiplyint:
            return floor(input*operandValue)
        case .add:
            return input+operandValue
        case .diff:
            return input-operandValue
        case .feed:
            return input
        case .diffabs:
            return abs(input-operandValue)
        case .greaterThan:
            return (input > operandValue) ? operandValue : nil
        case .lessThan:
            return (input < operandValue) ? operandValue : nil
        case .equalTo:
            return (input == operandValue) ? operandValue : nil
        case .notEqualTo:
            return (input != operandValue) ? operandValue : nil
        case .lessThanOrEqualTo:
            return (input <= operandValue) ? operandValue : nil
        }
    }
}

public extension ConceptValues {
    init(_ other: [Key: Value]) {
        self.init()
        addAll(other)
    }
    
    mutating func addAll(_ other: Dictionary?) {
        guard let other = other else { return }
        
        for key in other.keys {
            self[key] = other[key]
        }
    }
    
    // Returns a new dictionary reference. All in `other` overwrite `self`.
    func union(_ other: [Key: Value]?) -> [Key: Value] {
        guard let other = other else { return [Key: Value](self) }
        var modified = [Key: Value](self)
        modified.addAll(other)
        return modified
    }
}
