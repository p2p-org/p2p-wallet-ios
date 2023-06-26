import Foundation

import Foundation

struct Resource {
    let name: String
    let type: String
    let url: URL
    
    init(name: String, type: String, sourceFile: StaticString = #file) throws {
        self.name = name
        self.type = type
        
        // The following assumes that your test source files are all in the same directory, and the resources are one directory down and over
        // <Some folder>
        //  - Resources
        //      - <resource files>
        //  - <Some test source folder>
        //      - <test case files>
        let testCaseURL = URL(fileURLWithPath: "\(sourceFile)", isDirectory: false)
        let testsFolderURL = testCaseURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let resourcesFolderURL = testsFolderURL.appendingPathComponent("Resources", isDirectory: true)
        self.url = resourcesFolderURL.appendingPathComponent("\(name).\(type)", isDirectory: false)
    }
}

func getDataFromJSONTestResourceFile<T: Decodable>(fileName: String, decodedTo type: T.Type) throws -> T {
    let file = try Resource(name: fileName, type: "json")
    let data = try Data(contentsOf: file.url)
    return try JSONDecoder().decode(type, from: data)
}
