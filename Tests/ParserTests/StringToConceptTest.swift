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
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let deepIncrement = graph["Deep Increment"] else {
            XCTFail("Couldn't find Deep Increment")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(deepIncrement.vectors.count, 7)
        let cools = deepIncrement.vectors.filter { $0.from.first == "Cool" }
        guard cools.count == 2 else {
            XCTFail("Missing special assign character vectors")
            return
        }
        XCTAssertTrue(cools.contains(where: {
            $0.target.first == "7"
        }), "Missing Cool → 7 vector")
        XCTAssertTrue(cools.contains(where: {
            $0.target.first == "Man"
        }), "Missing Cool → Man vector")
        XCTAssertTrue(deepIncrement.vectors.contains(where: { vector in
            vector.from.toCode() == "Should Be Seven" && vector.operand?.toCode() == "Seven" && vector.operat0r == .equalTo && vector.target == []
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
        aa  Should Be Seven = Seven
        
        Increment
        ++++++++++++++
        1 -> One
        In Number + One -> Out Number
        """
        
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let deepIncrement = graph["Deep Increment"] else {
            XCTFail("Deep Increment not found")
            return
        }
        let increment = graph["Increment"]!
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
        
        let caseCorrected = code.split(separator: "\n").map { $0.capitalized }
        
        XCTAssertEqual(caseCorrected[0], "Once Upon A Concept")
        XCTAssertEqual(caseCorrected[1], "---------------")
        XCTAssertEqual(caseCorrected[2], "0 -> Image Pixel.Index")
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
        guard let drawHLine = graph["Draw H Line"] else {
            XCTFail("coudn't find Draw H Line")
            return
        }
        XCTAssertEqual(drawHLine.vectors[0].toCode(), "0 → At Index")
        XCTAssertEqual(drawHLine.vectors[1].toCode(), "7 → Width")
        XCTAssertEqual(drawHLine.vectors[2].toCode(), "0 → Image Pixel.Index")
        XCTAssertEqual(drawHLine.vectors[3].toCode(), "0.11 → Color.Green")
        XCTAssertEqual(drawHLine.vectors[4].toCode(), "0.73 → Color.Red")
        XCTAssertEqual(drawHLine.vectors[5].toCode(), "0.91 → Color.Blue")
        XCTAssertEqual(drawHLine.vectors.count, 11)
    }
    
    func test_decimalNumberSpecialOps() throws {
        let code = """
            Top
            ====
            0.01 -> Threshold
            Above.Image Pixel.Brightness -^ Image Pixel.Brightness -> Difference
            """
        var error: String? = nil
        let graph = ConceptGraph.fromCode(code, error: &error)!
        guard let rise = graph["Top"] else {
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
        guard let rise = graph["Top"] else {
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
        guard let rise = graph["Top"]  else {
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
        guard let rise = graph["Top"] else {
            XCTFail("coudn't find Top")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(rise.vectors.count, 3)
        
        let negativeVector = rise.vectors.first { vector in
            guard let target = vector.target.first else { return false }
            return target.isExclusion() && target == "!Even Worse"
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
        guard let rise = graph["Rise"] else {
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
        guard let con = graph["Convolution"] else {
            XCTFail("coudn't find Convolution")
            return
        }
        XCTAssertEqual(graph.count, 1)
        XCTAssertEqual(con.vectors.count, 1)
        XCTAssertEqual(con.vectors.first?.from.toCode(), "First.Candle.Index")
        XCTAssertEqual(con.vectors.first?.operand?.toCode(), "1")
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
        XCTAssertEqual(graph?["Rise"]?.vectors.count, 3)
        
        XCTAssertEqual(graph?["Rise"]?.vectors[2].from, ["Size"])
        XCTAssertEqual(graph?["Rise"]?.vectors[2].operand, ["Minimum Count"])
        XCTAssertEqual(graph?["Rise"]?.vectors[2].operat0r, .greaterThan)
        
        guard let vectorsSorted = graph?["Rise"]?.vectors.sorted(by: { v1, v2 in
            return v1.toCode() < v2.toCode()
        }) else {
            XCTFail("No vectors!")
            return
        }
        XCTAssertEqual(vectorsSorted[0].from.toCode(), "First.Candle.Index")
        XCTAssertEqual(vectorsSorted[0].operand?.toCode(), "1")
        XCTAssertEqual(vectorsSorted[0].target.toCode(), "Last.Candle.Index")
        XCTAssertEqual(vectorsSorted[0].operat0r, .add)
        XCTAssertEqual(vectorsSorted[1].from.toCode(), "Index Diff")
        XCTAssertEqual(vectorsSorted[1].operand?.toCode(), "1")
        XCTAssertEqual(vectorsSorted[1].target.toCode(), "Size")
        XCTAssertEqual(vectorsSorted[1].operat0r, .diff)
        XCTAssertEqual(graph?["Rise"]?.vectors[2].operat0r, .greaterThan)
    }
}
