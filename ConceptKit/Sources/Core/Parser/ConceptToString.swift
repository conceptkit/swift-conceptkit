extension ConceptGraph {
    func toCode() -> String {
        let concepts: [String] = self.sorted { v1, v2 in
            return v1.key < v2.key
        }.map {
            $0.value.toCode()
        }
        return concepts.joined(separator: "\n\n")
    }
}

extension Concept {
    func toCode() -> String {
        var lines: [String] = ["\(self.id)", "--------"]
        var valueFeedLines: [String] = []
        
        var otherVectors: [String] = []
        for vector in vectors {
            guard vector.isValueFeed else {
                otherVectors.append(vector.toCode())
                continue
            }
            valueFeedLines.append(vector.toCode())
        }
        
        lines.append(contentsOf: valueFeedLines)
        lines.append(contentsOf: otherVectors)
        return lines.joined(separator: "\n")
    }
}

extension Double {
    func renderTrimmed() -> String {
        guard Double(Int(self)) == self else {
            return "\(self)"
        }
        return "\(Int(self))"
    }
}

extension Concept.Vector {
    func toCode() -> String {
        let feedSymbol: String = Operator.feed.toCode()
        guard operat0r != .feed else {
            return from.toCode() + " "
            + feedSymbol + " "
                + target.toCode()
        }
        if let op = operand {
            if !target.isEmpty {
                return from.toCode() + " "
                + operat0r.toCode() + " "
                + op.toCode() + " "
                + feedSymbol + " "
                + target.toCode()
            } else {
                return from.toCode() + " "
                + operat0r.toCode() + " "
                + op.toCode()
            }
        } else {
            return from.toCode() + " "
            + operat0r.toCode() + " "
            + target.toCode()
        }
    }
    
    var isValueFeed: Bool {
        return from.numberValue != nil && operat0r == .feed
    }
}

extension Concept.Vector.Operator {
    func toCode() -> String {
        switch self {
        case .feed:
            return "→"
        case .add:
            return "+"
        case .diff:
            return "-"
        case .divide:
            return "/"
        case .multiply:
            return "*"
        case .multiplyint:
            return "**"
        case .diffabs:
            return "--"
        case .divideint:
            return "//"
        case .equalTo:
            return "="
        case .notEqualTo:
            return "!="
        case .greaterThan:
            return ">"
        case .lessThan:
            return "<"
        case .lessThanOrEqualTo:
            return "<="
        }
    }
}

extension ConceptIDPath {
    func toCode() -> String {
        return self.map { $0.toCode() }.joined(separator: ".")
    }
}

extension ConceptID {
    func toCode() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension ConceptValues {
    func toCode() -> String {
        return self.map { Concept.Vector(from: [$0.value.renderTrimmed()], target: $0.key, operat0r: .feed).toCode() }.joined(separator: "\n")
    }
}
