import Foundation

enum ConceptTokenGroup: CaseIterable, TokenGroupType {
    case conceptID
    case feedOperator
    case possibleOperator
    case possibleConceptSegmenter // a period .
    
    fileprivate func ifAllAreSameTokens(_ tokens: [Token]) -> Bool {
        var lastChar: Token?
        for token in tokens {
            guard token.type == .token else { return false }
            
            if let lastCharr = lastChar {
                guard lastCharr.string != "\n" else { continue }
                if lastCharr.string == token.string {
                    lastChar = token
                    continue
                } else {
                    return false
                }
            } else {
                lastChar = token
            }
        }
        return true
    }
    
    func shouldEnter(_ tokens: [Token]) -> NextAction {
        guard !tokens.isEmpty else { return .reject }
        
        // not in group yet
        switch self {
        case .conceptID:
            let containsIDBreakingChars = tokens.contains { t in
                t.type == .token || t.string == "\n"
            }
            guard !containsIDBreakingChars else { return .reject }
            let spaceCount = tokens.reduce(0) { (count, t) in
                guard t.type == .stickyTokens else { return count }
                return count + 1
            }
            guard spaceCount < tokens.count else { return .reject }
            
            return .accept
        case .feedOperator:
            if tokens.last?.string == "→" {
                return .accept
            }
            if tokens.last?.string == "-" {
                return .lookingLikeAccept
            }
            if tokens.areLastTokens(equal: "-",">") || tokens.areLastTokens(equal: "-",">",">")  {
                return .accept
            }
            return .reject
        case .possibleConceptSegmenter:
            guard ifAllAreSameTokens(tokens) else { return .reject }
            
            if tokens.count >= 3 {
                return .accept
            } else {
                return .lookingLikeAccept
            }
        case .possibleOperator:
            let containsNonTokens = tokens.contains { t in
                t.type != .token || t.string == "\n"
            }
            guard !containsNonTokens else { return .reject }
            return .accept
        }
    }
    
    func shouldContinueOrExit(_ tokens: [Token]) -> NextAction {
        // already in group
        switch self {
        case .conceptID:
            guard tokens.last?.string.contains("\n") != true else { return .reject }
            guard tokens.last?.type == .token else { return .reject }
            
            return .accept
        case .feedOperator:
            if tokens.areLastTokens(equal: "-",">",">") {
                return .acceptAndFinish
            } else {
                return .reject
            }
        case .possibleConceptSegmenter:
            guard ifAllAreSameTokens(tokens) && tokens.join().trim() != "" else { return .reject }
            return .accept
        case .possibleOperator:
            guard let lastToken = tokens.last else { return .reject }
            return (lastToken.type == .token && lastToken.string != "\n") ? .accept : .reject
        }
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array where Element == Token {
    func join() -> String {
        var returnStr = ""
        for element in self {
            returnStr += element.string
        }
        return returnStr
    }
    
    // TODO make reverse possible
    func areLastTokens(equalTo: [String]) -> Bool {
        var equalIndex = equalTo.count - 1
        var rollingCacheIndex = self.count - 1
        while equalIndex >= 0 {
            if rollingCacheIndex >= 0 {
                if self[rollingCacheIndex].string != equalTo[equalIndex] {
                    return false
                }
            } else {
                // not enough tokens in this array
                return false
            }
            rollingCacheIndex -= 1
            equalIndex -= 1
        }
        return true
    }
    
    // TODO make reverse possible
    func areLastTokens(equal: String...) -> Bool {
        return areLastTokens(equalTo: equal)
    }
}
