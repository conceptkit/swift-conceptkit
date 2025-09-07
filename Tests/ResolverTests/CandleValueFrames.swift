import QuartzCore
import ConceptKit

public class CandleValueFrames {
    public struct Candle: Codable {
        var openTime: Date
        var closeTime: Date
        var open: Double
        var closePrice: Double
        var high: Double
        var low: Double
        var numberOfTrades: Int
        var volume: Double
    }
    
    var array: [Candle]
    
    init?(file: String) {
        let url = URL(fileURLWithPath: file)
        do {
            self.array =  try JSONDecoder().decode([Candle].self, from: Data(contentsOf: url))
        } catch {
            return nil
        }
    }
}

extension CandleValueFrames: ConceptValueFrames {
    public var count: Int {
        return array.count
    }

    public subscript(index: Int) -> ConceptValues {
        get {
            return array[index].toConceptValues().union([
                ["count"] : Double(array.count)
            ])
        }
        set {
            array[index] = newValue.toCandle()
        }
    }
    public func commitEdits() -> Bool {
        // NO-OP
        return false
    }
}

// - MARK: To/From Candle/ConceptValues

public extension CandleValueFrames.Candle {
    func toConceptValues() -> ConceptValues {
        return [
            ["open time"] : openTime.timeIntervalSince1970,
            ["close time"] : closeTime.timeIntervalSince1970,
            ["open price"] : open,
            ["close price"] : closePrice,
            ["high price"] : high,
            ["low price"] : low,
            ["number of trades"] : Double(numberOfTrades),
            ["volume"] : volume,
        ]
    }
}

public extension ConceptValues {
    func toCandle() -> CandleValueFrames.Candle {
        return CandleValueFrames.Candle(
            openTime: Date(timeIntervalSince1970: Double(self[["open time"]] ?? 0.0)),
            closeTime: Date(timeIntervalSince1970: Double(self[["close time"]] ?? 0.0)),
            open: Double(self[["open price"]] ?? 0.0),
            closePrice: Double(self[["close price"]] ?? 0.0),
            high: Double(self[["high price"]] ?? 0.0),
            low: Double(self[["low price"]] ?? 0.0),
            numberOfTrades: Int(self[["low price"]] ?? 0.0),
            volume: Double(self[["volume"]] ?? 0.0)
        )
    }
}
