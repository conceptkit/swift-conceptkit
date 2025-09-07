import XCTest
@testable import ConceptKit

class StringToConceptTest: XCTestCase {

    override func setUpWithError() throws {
    }
    
    override func tearDownWithError() throws {
    }
    
    func test_specialAssignChar() throws {
        let code = """
        Deep Increment
        ------------
        6 -> Six
        7 -> Seven
        Increment.Out Number -> Should Be Seven
        Six -> Increment.In Number
        Cool → 7
        Cool → Man
        Should Be Seven = Seven
        """
        
        guard let deepIncrement = AssertConceptExists(code, concept: "deep increment") else { return }
        XCTAssertEqual(deepIncrement.vectors.count, 7)
        let cools = deepIncrement.vectors.filter { $0.from.first == "cool" }
        guard cools.count == 2 else {
            XCTFail("Missing special assign character vectors")
            return
        }
        XCTAssertTrue(cools.contains(where: {
            $0.target.first == "7"
        }), "missing cool → 7 vector")
        XCTAssertTrue(cools.contains(where: {
            $0.target.first == "man"
        }), "Missing cool → man vector")
        XCTAssertTrue(deepIncrement.vectors.contains(where: { vector in
            vector.from.toCode() == "should be seven" && vector.operand.toCode() == "seven" && vector.operat0r == .equalTo && vector.target == []
        }), "Missing condition vector");
    }
    
    func test_twoConcepts() throws {
        let code = """
        Deep Increment
        ---------
        6 -> Six
        7 -> Seven
        Increment.Out Number -> Should Be Seven
        Six -> Increment.In Number
        Should Be Seven = Seven
        
        Increment
        ++++++++++++++
        1 -> One
        In Number + One -> Out Number
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let deepIncrement = graph["deep increment"] else {
            XCTFail("Deep Increment not found")
            return
        }
        let increment = graph["increment"]!
        XCTAssertEqual(graph.count, 2)
        XCTAssertEqual(deepIncrement.vectors.count, 5)
        XCTAssertEqual(increment.vectors.count, 2)
    }
    
    func test_IsCaseInsensative() throws {
        let code = """
        Once upon a concept
        ---------------
        0 -> Image Pixel.index
        4 -> total lines
        magenta -> Color
        0 -> current Line
        Image Pixel.index + 2 -> Draw V Line.Image Pixel.Index
        CuRrent Line + 1 -> CurRent Line
        Current Line = Total Lines
        """
        
        guard let concept = AssertConceptExists(code, concept: "once upon a concept") else { return }
        
        AssertVectorExists(concept, from: "0", target: "image pixel.index")
        AssertVectorExists(concept, from: "image pixel.index", target: "draw v line.image pixel.index", operand: "2")
        AssertVectorExists(concept, from: "current line", operand: "total lines")
    }
    
    func test_exactVectorOrder() throws {
        let code = """
        
        Me
        ----
        7 = 7

        Draw H Line
        -------------
        0 -> At Index
        7 -> Width
        0 -> Image Pixel.Index
        0.11 -> Color.Green
        0.73 -> Color.Red
        0.91 -> Color.Blue
        At Index -> Image Pixel.Index
        At Index + Width -> End Index
        Color -> Image Pixel
        Image Pixel.Index + 1 -> Image Pixel.Index
        Image Pixel.Index = End Index
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let drawHLine = graph["draw h line"] else {
            XCTFail("coudn't find Draw H Line")
            return
        }
        XCTAssertEqual(drawHLine.vectors[0].toCode(), "0 → at index")
        XCTAssertEqual(drawHLine.vectors[1].toCode(), "7 → width")
        XCTAssertEqual(drawHLine.vectors[2].toCode(), "0 → image pixel.index")
        XCTAssertEqual(drawHLine.vectors[3].toCode(), "0.11 → color.green")
        XCTAssertEqual(drawHLine.vectors[4].toCode(), "0.73 → color.red")
        XCTAssertEqual(drawHLine.vectors[5].toCode(), "0.91 → color.blue")
        XCTAssertEqual(drawHLine.vectors.count, 11)
    }
    
    func test_decimalNumberSpecialOps() throws {
        let code = """
            Top
            ====
            0.01 -> Threshold
            Above.Image Pixel.Brightness -- Image Pixel.Brightness -> Difference
            """
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["top"] else {
            XCTFail("coudn't find Top")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 2)
    }
    
    func test_oneSidedInclusion() throws {
        let code = """
            Top
            ====
            Inclusion Here
            Inclusion There
            """
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["top"] else {
            XCTFail("Top missing")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 2)
    }
    
    func test_negativeValue() throws {
        let code = """
            Top
            ===
            -10 -> Candle.Index
            Candle.High Price - Candle.Low Price -> High Price minus Low Price
            """
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["top"]  else {
            XCTFail("coudn't find Top")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 2)
    }
    
    func test_exclusion() throws {
        let code = """
            Top
            ===
            -10 -> Candle.Index
            Negativo -> !Even Worse
            Candle.High Price - Candle.Low Price -> High Price minus Low Price
            """
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["top"] else {
            XCTFail("coudn't find Top")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 3)
        
        let negativeVector = rise.vectors.first { vector in
            guard let target = vector.target.first else { return false }
            return target.isExclusion() && target == "!even worse"
        }
        
        guard negativeVector != nil else {
            XCTFail("Expected exclusion vector")
            return
        }
        XCTAssertEqual(negativeVector?.target.first?.isExclusion(), true)
    }
    
    func test_startingValuesToConcepts() {
        let code = """
        Rise
        =====
        3 -> Three
        0 -> First.Candle.Index
        Index Diff - 1 -> Size
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["rise"] else {
            XCTFail("Coudn't find Rise")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 3)
    }
    
    func test_operand() {
        let code = """
        Convolution
        =====
        First.Candle.Index + 1 -> Last.Candle.Index
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let con = graph["convolution"] else {
            XCTFail("coudn't find Convolution")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(con.vectors.count, 1)
        XCTAssertEqual(con.vectors.first?.from.toCode(), "first.candle.index")
        XCTAssertEqual(con.vectors.first?.operand.toCode(), "1")
    }
   
    func test_stringToConcepts() {
        let conceptCode = """
        Rise
        =====
        First.Candle.Index + 1 -> Last.Candle.Index
        Index Diff - 1 -> Size
        Size > Minimum Count
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(conceptCode, error: &error)
        
        XCTAssertEqual(graph?.count, 1)
        XCTAssertEqual(graph?["rise"]?.vectors.count, 3)
        
        XCTAssertEqual(graph?["rise"]?.vectors[2].from, ["size"])
        XCTAssertEqual(graph?["rise"]?.vectors[2].operand, ["minimum count"])
        XCTAssertEqual(graph?["rise"]?.vectors[2].operat0r, .greaterThan)
        
        guard let vectorsSorted = graph?["rise"]?.vectors.sorted(by: { v1, v2 in
            return v1.toCode() < v2.toCode()
        }) else {
            XCTFail("No vectors!")
            return
        }
        XCTAssertEqual(vectorsSorted[0].from.toCode(), "first.candle.index")
        XCTAssertEqual(vectorsSorted[0].operand.toCode(), "1")
        XCTAssertEqual(vectorsSorted[0].target.toCode(), "last.candle.index")
        XCTAssertEqual(vectorsSorted[0].operat0r, .add)
        XCTAssertEqual(vectorsSorted[1].from.toCode(), "index diff")
        XCTAssertEqual(vectorsSorted[1].operand.toCode(), "1")
        XCTAssertEqual(vectorsSorted[1].target.toCode(), "size")
        XCTAssertEqual(vectorsSorted[1].operat0r, .diff)
        XCTAssertEqual(graph?["rise"]?.vectors[2].operat0r, .greaterThan)
    }
    
    // MARK: -- helpers
    
    func AssertConceptExists(_ code: String, concept: ConceptID) -> Concept? {
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let concept = graph[concept] else {
            XCTFail("`\(concept)` not found")
            return nil
        }
        return concept
    }
    
    func AssertVectorExists(_ concept: Concept, from: String="", target: String="", operand: String="") {
        guard concept.vectors.contains(where: {
            var matched = !from.isEmpty ? (from == $0.from.toCode()) : true
            if !matched {
                return false
            }
            matched = !target.isEmpty ? (target == $0.target.toCode()) : true
            if !matched {
                return false
            }
            matched = !operand.isEmpty ? (operand == $0.operand.toCode()) : true
            return true
        }) else {
            XCTFail("Concept `\(concept.id)` did not contain specified")
            return
        }
    }
}
