import Foundation

class ConceptStringTokenizer: Tokenizer {
    
    let tokens: [Character] = ["/","\\","*","[","]","{","}","(",")",":",";",",","?","|","+","-","*","=","^","%","&","<",">","→","\n"]
    let discardableTokens: [Character] = []
    let stickyTokens: [Character] = [" ", "\r", "\t"]
    
    init?(string: String) {
        super.init(streamReader: StringStreamReader(string), tokens: tokens, discardableTokens: discardableTokens, stickyTokens: stickyTokens, lookBackCache: 10)
    }
}
