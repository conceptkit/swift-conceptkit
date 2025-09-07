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
        
        XCTAssertEqual(lines[0], "rise")
        XCTAssertEqual(lines[1], "--------")
        XCTAssertEqual(lines[2], "4 → minimum count")
        XCTAssertEqual(lines[3], "0 → first.candle.index")
        XCTAssertEqual(lines[4], "first.candle.index + 1 → first.candle.index")
        XCTAssertEqual(lines[5], "index diff + 1 → size")
        XCTAssertEqual(lines[6], "size > minimum count")
    }
    
    private func makeConcepts() -> ConceptGraph {
        var graph = ConceptGraph()
        graph = graph.modify("rise")
            .addValueFeed(4, forInclusion: ["minimum count"])
            .addValueFeed(0, forInclusion: ["first", "candle"] + DataSources.kIndex)
            .addVector(
                .init(
                    from: ["first", "candle"] + DataSources.kIndex,
                    target: ["first", "candle"] + DataSources.kIndex,
                    operand: ["1"],
                    operat0r: .add))
            .addVector(
                .init(
                    from: ["index diff"],
                    target: ["size"],
                    operand:["1"],
                    operat0r: .add))
            .addVector(
                .init(
                    from: ["size"],
                    target: ["minimum count"],
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
        ["index"]
    }
}
