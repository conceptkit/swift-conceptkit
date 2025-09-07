import XCTest
@testable import ConceptKit

final class ResolveConceptTests: XCTestCase {

    func test_SimpleMath() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "simple_math", ext: "txt")
        guard let cv = try resolveConcept(graph, conceptID: "simple math") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("delta price")] else {
            XCTFail("No main result!")
            return
        }
        
        guard let highPrice = cv[path("candle.high price")] else {
            XCTFail("No Candle.High Price!")
            return
        }
        guard let lowPrice = cv[path("candle.low price")] else {
            XCTFail("No candle.low price!")
            return
        }
        
        let expected = (highPrice - lowPrice)
        guard expected == result else {
            XCTFail("Expected result: \(expected), was: \(result)")
            return;
        }
    }
    
    func test_SquareNumber() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "test_square", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "test square") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("square.result")] else {
            XCTFail("No `square.result`!")
            return
        }
        
        XCTAssertTrue(result == 49, "`square.result` wasn't 49!")
    }
    
    func test_ExponentNumber() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "test-exponent", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "test exponent") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("exponent.result")] else {
            XCTFail("No `Exponent.Result`!")
            return
        }
        
        XCTAssertEqual(result, 32, "`exponent.result` wasn't 32!")
    }
    
    func test_FirstBullCandle() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "bull", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "bull") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let indexOf = cv["candle.index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(indexOf, 2, "Unexpected `candle` index was Bull")
    }
    
    func test_FourthBullCandle() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "fourth-bull", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "fourth bull") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let bullIndex = cv["bull.index"] else {
            XCTFail("No main result!")
            return
        }
        
        guard let candleIndex = cv["bull.candle.index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(bullIndex, 3, "Unexpected Bull.Index")
        XCTAssertEqual(candleIndex, 7, "Unexpected `Candle` index was Bull")
    }
    
    func test_BullCluster() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "bull_cluster", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "bull cluster") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let indexOf = cv[path("after.bull.candle.index")] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(indexOf, 4, "Unexpected `Candle` index")
    }
    
    func test_ThirdBullCluster() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "third-bull-cluster", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "third bull cluster") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let bullClusterIndex = cv["bull cluster.index"] else {
            XCTFail("No main result!")
            return
        }
        
        guard let candleIndex = cv["bull cluster.first.bull.candle.index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(bullClusterIndex, 2, "Unexpected Bull Cluster.Index")
        XCTAssertEqual(candleIndex, 14, "Unexpected starting `Candle` of 3rd Bull Cluster")
    }
    
    func test_Rise() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "rise_trend", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "medium rise") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let firstCandleIndex = cv[path("bull cluster.first.bull.candle.index")] else {
            XCTFail("No `bull cluster` index!")
            return
        }
        
        XCTAssertEqual(firstCandleIndex, 6, "`bull cluster.first.candle.index` wasn't right!")
    }
    
    // MARK: - convenience methods
    
    private func path(_ conceptPathString: String) -> ConceptIDPath {
        return conceptPathString.split(separator: ".").map { String($0) }
    }
    
    private func resolveConcept(_ graph: ConceptGraph, conceptID: ConceptID, errorString: ((ConceptValues) -> String?)? = nil) throws -> ConceptValues? {
        guard let concept = graph[conceptID] else {
            throw "Concept `\(conceptID)` not found in graph"
        }
        
        let file = Bundle.module.path(forResource: "twoMonths", ofType: "json")!
        let dataSources: [ConceptID: ConceptValueFrames] = ["candle": CandleValueFrames(file: file)!]
        
        let conceptValuesInterface = ConceptValuesInterface(dataSources: dataSources)
        var isHardStop = false
        var trace = Trace()
        guard let cv = concept.resolve(values: conceptValuesInterface, graph: graph, isHardStop: &isHardStop, trace: &trace) else {
            if isHardStop {
                throw "Fatally can't build concept `\(conceptID)`"
            } else {
                throw "Can't build concept `\(conceptID)`"
            }
        }
        
        if let errorString = errorString {
            if let analysisError = errorString(cv) {
                throw "Concept '\(concept)' build wrong: \(analysisError)"
            }
        }
        return cv
    }
}

extension String: Error {}

extension ConceptValues {
    subscript(_ path: String) -> Double? {
        let split = path.split(separator: ".").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count > 0 }
        return self[split]
    }
}
