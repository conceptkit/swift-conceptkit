import Foundation

protocol TokenGroupType {
    func shouldEnter(_ tokens: [Token]) -> NextAction
    func shouldContinueOrExit(_ tokens: [Token]) -> NextAction
}

extension TokenGroupType {
    func shouldEnter(_ tokens: Token...) -> NextAction {
        return shouldEnter(tokens)
    }
    func shouldContinueOrExit(_ tokens: Token...) -> NextAction {
        return shouldContinueOrExit(tokens)
    }
}
enum NextAction {
    case acceptAndFinish
    case lookingLikeAccept
    case accept
    case reject
}

/// Will group tokens according to the `TokenGroupType`s that are passed in. Tokens in-between `TokenGroup`s are returned with a nil `TokenGroupType`
/// and an array with a single token in it.
class TokenGrouper<E : TokenGroupType>: Sequence, IteratorProtocol {
    struct TokenGroup {
        let type: E?
        let tokens: [Token]
        
        init(_ type: E?, _ tokens: [Token]) {
            self.type = type
            self.tokens = tokens
        }
        
        init(_ tokens: Token...) {
            self.init(nil, tokens)
        }
        
        init(_ tokens: [Token]) {
            self.init(nil, tokens)
        }
    }
    typealias Element = TokenGroup
    
    let tokenizer: Tokenizer
    let groupTypes: [E]
    
    init(_ tokenizer: Tokenizer, groupTypes: [E]) {
        self.tokenizer = tokenizer
        self.groupTypes = groupTypes
    }
    
    func next() -> TokenGroup? {
        guard let token: Token = tokenizer.next() else { return nil }
        
        // find first matching `groupType`
        groupTypeLoop: for groupType in groupTypes {
            let result = groupType.shouldEnter(token)
            switch result {
            case .lookingLikeAccept:
                var tokens = [token]
                let definitive = continueTryingGroupTypeUntilDefinitive(groupType, soFar: &tokens)
                if definitive == .accept {
                    return continueAcceptingGroupTypeUntilComplete(groupType, tokens: tokens)
                } else if definitive == .acceptAndFinish {
                    return TokenGroup(groupType, tokens)
                } else if definitive == .reject {
                    // put all the tokens back except for the original for use later
                    tokenizer.replay(tokens.count - 1)
                    continue groupTypeLoop
                }
            case .accept:
                return continueAcceptingGroupTypeUntilComplete(groupType, tokens: [token])
            case .acceptAndFinish:
                return TokenGroup(groupType, [token])
            case .reject:
                continue groupTypeLoop
            }
        }
        
        // latest token was rejected by all
        return TokenGroup(token)
    }
    
    private func continueTryingGroupTypeUntilDefinitive(_ groupType: E, soFar: inout [Token]) -> NextAction {
        for token in tokenizer {
            soFar.append(token)
            let result = groupType.shouldEnter(soFar)
            
            // continue looping while its uncertain
            guard result == .lookingLikeAccept else {
                return result
            }
        }
        
        return .reject
    }
    
    private func continueAcceptingGroupTypeUntilComplete(_ groupType: E, tokens: [Token]) -> TokenGroup? {
        guard let currentToken = tokenizer.next() else { return TokenGroup(groupType, tokens) }
        var soFar = Array(tokens)
        soFar.append(currentToken)
        
        repeat {
            let result = groupType.shouldContinueOrExit(soFar)
            
            guard result != .acceptAndFinish else {
                return TokenGroup(groupType, soFar)
            }
            
            if result == .reject {
                // put back
                tokenizer.replay(1)
                
                _ = soFar.removeLast()
                // go onto return token
                break
            }
            
            if let localNextToken = tokenizer.next() {
                soFar.append(localNextToken)
            } else {
                break
            }
        } while true
        
        return TokenGroup(groupType, soFar)
    }
}
