import XCTest
@testable import ConceptKit

final class ResolveConceptTests: XCTestCase {

    func test_SimpleMath() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "simple_math", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Simple Math") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("Delta Price")] else {
            XCTFail("No main result!")
            return
        }
        
        guard let highPrice = cv[path("Candle.High Price")] else {
            XCTFail("No Candle.High Price!")
            return
        }
        guard let lowPrice = cv[path("Candle.Low Price")] else {
            XCTFail("No Candle.Low Price!")
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
        
        guard let cv = try resolveConcept(graph, conceptID: "Test Square") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("Square.Result")] else {
            XCTFail("No `Square.Result`!")
            return
        }
        
        XCTAssertTrue(result == 49, "`Square.Result` wasn't 49!")
    }
    
    func test_ExponentNumber() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "test-exponent", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Test Exponent") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let result = cv[path("Exponent.Result")] else {
            XCTFail("No `Exponent.Result`!")
            return
        }
        
        XCTAssertEqual(result, 32, "`Exponent.Result` wasn't 32!")
    }
    
    func test_FirstBullCandle() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "bull", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Bull") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let indexOf = cv["Candle.Index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(indexOf, 2, "Unexpected `Candle` index was Bull")
    }
    
    func test_FourthBullCandle() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "fourth-bull", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Fourth Bull") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let bullIndex = cv["Bull.Index"] else {
            XCTFail("No main result!")
            return
        }
        
        guard let candleIndex = cv["Bull.Candle.Index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(bullIndex, 3, "Unexpected Bull.Index")
        XCTAssertEqual(candleIndex, 7, "Unexpected `Candle` index was Bull")
    }
    
    func test_BullCluster() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "bull_cluster", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Bull Cluster") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let indexOf = cv[path("After.Bull.Candle.Index")] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(indexOf, 4, "Unexpected `Candle` index")
    }
    
    func test_ThirdBullCluster() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "third-bull-cluster", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Third Bull Cluster") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let bullClusterIndex = cv["Bull Cluster.Index"] else {
            XCTFail("No main result!")
            return
        }
        
        guard let candleIndex = cv["Bull Cluster.First.Bull.Candle.Index"] else {
            XCTFail("No main result!")
            return
        }
        
        XCTAssertEqual(bullClusterIndex, 2, "Unexpected Bull Cluster.Index")
        XCTAssertEqual(candleIndex, 14, "Unexpected starting `Candle` of 3rd Bull Cluster")
    }
    
    func test_Rise() throws {
        let graph = try ConceptGraphLoader.loadGraph(graphFileName: "rise_trend", ext: "txt")
        
        guard let cv = try resolveConcept(graph, conceptID: "Medium Rise") else {
            XCTFail("Could not build.")
            return
        }
        
        guard let firstCandleIndex = cv[path("Bull Cluster.First.Bull.Candle.Index")] else {
            XCTFail("No `Bull Cluster` index!")
            return
        }
        
        XCTAssertEqual(firstCandleIndex, 6, "`Bull Cluster.First.Candle.Index` wasn't right!")
    }
    
    // MARK: - convenience methods
    
    private func path(_ conceptPathString: String) -> ConceptIDPath {
        return conceptPathString.split(separator: ".").map { String($0) }
    }
    
    private func resolveConcept(_ graph: ConceptGraph, conceptID: ConceptID, errorString: ((ConceptValues) -> String?)? = nil) throws -> ConceptValues? {
        guard let concept = graph[conceptID] else {
            throw "Concept not found in graph"
        }
        
        let file = Bundle.module.path(forResource: "twoMonths", ofType: "json")!
        let dataSources: [ConceptID: ConceptValueFrames] = ["Candle": CandleValueFrames(file: file)!]
        
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
