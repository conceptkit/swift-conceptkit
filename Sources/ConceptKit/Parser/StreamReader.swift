protocol StreamReader {
    func nextChar() -> Character?
}

class StringStreamReader: StreamReader {
    var string: String
    var index = -1
    
    init(_ string: String) {
        self.string = string
    }
    
    func nextChar() -> Character? {
        guard self.index + 1 < self.string.count else { return nil }
        self.index += 1
        return self.string[index]
    }
}

extension String {
    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
}
