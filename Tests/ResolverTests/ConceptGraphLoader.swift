import Foundation
import ConceptKit

public enum ConceptGraphLoadError: Error {
    case couldntLoadFile
    case couldntParseConceptCode
}

public class ConceptGraphLoader {
    static func loadGraph(graphFileName: String, ext: String) throws -> ConceptGraph {
        func read(_ fileURL: URL) -> String? {
            do {
                return try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                print("error: \(error)")
                return nil
            }
        }
        
        guard let url = Bundle.module.url(forResource: graphFileName, withExtension: ext), let graphCode = read(url) else {
            throw ConceptGraphLoadError.couldntLoadFile
        }
        
        var parseErrorString: String?
        guard let graph = ConceptGraph.fromCode(graphCode, error: &parseErrorString) else {
            throw ConceptGraphLoadError.couldntParseConceptCode
        }
        
        return graph
    }
}
