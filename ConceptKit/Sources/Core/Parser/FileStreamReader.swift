import Foundation

class FileStreamReader  {
    
    let encoding : String.Encoding
    let chunkSize : Int
    
    private let fileHandle: FileHandle
    private let buffer: NSMutableData
    private var stored: [Character] = Array()
    private var stored_idx: Int = 0
    private var stored_cnt: Int = 0
    private var atEof: Bool = false
    
    init?(path: String, encoding: String.Encoding = .utf8, chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = encoding
        
        if let fileHandle = FileHandle(forReadingAtPath: path), let buffer = NSMutableData(capacity: chunkSize) {
            self.fileHandle = fileHandle
            self.buffer = buffer
            self.stored = Array()
            self.stored_idx = 0
        } else {
            return nil
        }
    }
    
    deinit {
        self.close()
    }
    
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.length = 0
        stored_cnt = 0
        self.atEof = false
    }
    
    func close() -> Void {
        fileHandle.closeFile()
    }
}

extension FileStreamReader: StreamReader {
    func nextChar() -> Character? {
        if self.atEof {
            return nil
        }
        
        if stored_cnt > (stored_idx + 1) {
            stored_idx += 1
            return stored[stored_idx]
        }
        
        let tmpData = fileHandle.readData(ofLength: chunkSize)
        if tmpData.count == 0 {
            self.atEof = true
            return nil
        }
        
        if let s = String(data: tmpData, encoding: encoding) {
            stored = s.map { $0 }
            stored_idx = 0
            stored_cnt = stored.count
        }
        return stored[0];
    }
}

