public struct Token {
    let string: String
    let type: TokenType
    let offset: Int
    
    init(_ token: String, _ type: TokenType, _ offset: Int) {
        self.string = token
        self.type = type
        self.offset = offset
    }
    
    init(_ chars: [Character], _ type: TokenType, _ offset: Int) {
        self.string = String(chars)
        self.type = type
        self.offset = offset
    }
}
public enum TokenType {
    case stickyTokens
    case token
    case normal
}

/// A string tokenizer with extra functionality. The token returned is a string, but also has a type and an offset index.
class Tokenizer: Sequence, IteratorProtocol {
    typealias Element = Token
    
    private let streamReader: StreamReader
    
    private let tokens: Set<Character>
    private let discardableTokens: Set<Character>
    // Any tokens that are 'sticky' will return as a single token
    private let stickyTokens: Set<Character>
    // How far back in memory to keep a rolling cache
    private let lookBackCache: Int
    
    private var index: Int = -1
    private var rollingCache = [Token]()
    private var returnRollingCacheFor: Int = 0
    
    var history: [Token] {
        guard returnRollingCacheFor == 0 else {
            return rollingCache.dropLast(returnRollingCacheFor)
        }
        return rollingCache
    }
    
    init?(streamReader: StreamReader, tokens: [Character], discardableTokens: [Character] = [], stickyTokens: [Character] = [], lookBackCache: Int = 100) {
        self.streamReader = streamReader
        self.tokens = Set(tokens)
        self.discardableTokens = Set(discardableTokens)
        self.stickyTokens = Set(stickyTokens)
        self.lookBackCache = lookBackCache
    }
    
    private var extraChar: Character?
    func next() -> Token? {
        guard returnRollingCacheFor <= 0 else {
            let value = rollingCache[rollingCache.count - returnRollingCacheFor]
            returnRollingCacheFor -= 1
            return value
        }
        
        var currentToken: [Character] = Array()
        var currentTokenType: TokenType = .token
        var currentTokenIndex: Int = index
        
        func returnValue(char: Character? = nil) -> Token? {
            guard currentToken.count > 0 else { return nil }
            if let char = char {
                self.extraChar = char
            }
            return Token(currentToken, currentTokenType, currentTokenIndex)
        }
        while let char = extraChar ?? streamReader.nextChar() {
            index += (extraChar == nil ? 1 : 0)
            self.extraChar = nil
            if self.stickyTokens.contains(char) {
                if currentTokenType == .stickyTokens {
                    currentToken.append(char)
                } else {
                    if let val = returnValue(char: char) {
                        return cachePassThrough(val)
                    } else {
                        // start sticky token
                        currentToken.append(char)
                        currentTokenIndex = index
                        currentTokenType = .stickyTokens
                    }
                }
            } else if self.discardableTokens.contains(char) {
                if let val = returnValue(char: char) {
                    return cachePassThrough(val)
                }
                // discard
            } else if self.tokens.contains(char) {
                if let val = returnValue(char: char) {
                    return cachePassThrough(val)
                } else {
                    // just return single letter as token
                    currentTokenIndex = index
                    currentTokenType = .token
                    currentToken.append(char)
                    if let val = returnValue() {
                        return cachePassThrough(val)
                    }
                }
            } else {
                if currentTokenType == .stickyTokens, let val = returnValue(char: char) {
                    return cachePassThrough(val)
                }
                // its not a token, so just accumulate a token
                currentTokenType = .normal
                if currentToken.isEmpty {
                    currentTokenIndex = index
                }
                currentToken.append(char)
            }
        }
        if let val = returnValue() {
            return cachePassThrough(val)
        }
        return nil
    }
    
    public func replay(_ amount: Int) {
        guard amount <= rollingCache.count else { return }
        self.returnRollingCacheFor = amount
    }
    
    public func cancelReplay() {
        self.returnRollingCacheFor = 0
    }
    
    private func cachePassThrough(_ token: Token) -> Token {
        if rollingCache.count == lookBackCache {
            _ = rollingCache.remove(at: 0)
        }
        rollingCache.append(token)
        return token
    }
}
