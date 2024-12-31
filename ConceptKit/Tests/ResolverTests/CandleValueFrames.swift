import QuartzCore
import Core

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
                ["Count"] : Double(array.count)
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
            ["Open Time"] : openTime.timeIntervalSince1970,
            ["Close Time"] : closeTime.timeIntervalSince1970,
            ["Open Price"] : open,
            ["Close Price"] : closePrice,
            ["High Price"] : high,
            ["Low Price"] : low,
            ["Number of Trades"] : Double(numberOfTrades),
            ["Volume"] : volume,
        ]
    }
}

public extension ConceptValues {
    func toCandle() -> CandleValueFrames.Candle {
        return CandleValueFrames.Candle(
            openTime: Date(timeIntervalSince1970: Double(self[["Open Time"]] ?? 0.0)),
            closeTime: Date(timeIntervalSince1970: Double(self[["Close Time"]] ?? 0.0)),
            open: Double(self[["Open Price"]] ?? 0.0),
            closePrice: Double(self[["Close Price"]] ?? 0.0),
            high: Double(self[["High Price"]] ?? 0.0),
            low: Double(self[["Low Price"]] ?? 0.0),
            numberOfTrades: Int(self[["Low Price"]] ?? 0.0),
            volume: Double(self[["Volume"]] ?? 0.0)
        )
    }
}
