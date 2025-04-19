import XCTest
@testable import ConceptKit

class ConceptToStringTest: XCTestCase {
    override func setUpWithError() throws {
    }
    
    override func tearDownWithError() throws {
    }
    
    func test_startingValuesToString() {
        var graph = ConceptGraph()
        graph = graph.modify("My Concept")
            .addValueFeed(4, forInclusion: ["Four"])
            .addValueFeed(0, forInclusion: ["Zero"])
            .addVector(
                .init(
                    from: ["First", "Inclusion"],
                    target: ["Second", "Inclusion"],
                    operand: [],
                    operat0r: .feed))
            .addVector(
                .init(
                    from: ["Size"],
                    target: ["Minimum Count"],
                    operand: [],
                    operat0r: .greaterThan))
            .graph
        
        let code = graph.toCode()
        let lines = code.split(separator: "\n")
        
        XCTAssertEqual(lines[0], "My Concept")
        XCTAssertEqual(lines[1], "--------")
        XCTAssertEqual(lines[2], "4 → Four")
        XCTAssertEqual(lines[3], "0 → Zero")
        XCTAssertEqual(lines[4], "First.Inclusion → Second.Inclusion")
        XCTAssertEqual(lines[5], "Size > Minimum Count")
    }
    
    func test_makeConceptString() {
        let knowledge = makeConcepts()
        let code = knowledge.toCode()
        let lines = code.split(separator: "\n")
        
        XCTAssertEqual(lines[0], "Rise")
        XCTAssertEqual(lines[1], "--------")
        XCTAssertEqual(lines[2], "4 → Minimum Count")
        XCTAssertEqual(lines[3], "0 → First.Candle.Index")
        XCTAssertEqual(lines[4], "First.Candle.Index + 1 → First.Candle.Index")
        XCTAssertEqual(lines[5], "Index Diff + 1 → Size")
        XCTAssertEqual(lines[6], "Size > Minimum Count")
    }
    
    private func makeConcepts() -> ConceptGraph {
        var graph = ConceptGraph()
        graph = graph.modify("Rise")
            .addValueFeed(4, forInclusion: ["Minimum Count"])
            .addValueFeed(0, forInclusion: ["First", "Candle"] + DataSources.kIndex)
            .addVector(
                .init(
                    from: ["First", "Candle"] + DataSources.kIndex,
                    target: ["First", "Candle"] + DataSources.kIndex,
                    operand: ["1"],
                    operat0r: .add))
            .addVector(
                .init(
                    from: ["Index Diff"],
                    target: ["Size"],
                    operand:["1"],
                    operat0r: .add))
            .addVector(
                .init(
                    from: ["Size"],
                    target: ["Minimum Count"],
                    operand: [],
                    operat0r: .greaterThan
                )
            )
            .graph
        return graph
    }
}

fileprivate typealias DataSources = [ConceptIDPath: ConceptValueFrames]
fileprivate extension DataSources {
    // the magical index key
    static var kIndex: ConceptIDPath {
        ["Index"]
    }
}
