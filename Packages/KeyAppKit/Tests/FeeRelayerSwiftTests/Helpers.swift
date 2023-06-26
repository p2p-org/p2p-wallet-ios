import Foundation

func getDataFromJSONTestResourceFile<T: Decodable>(fileName: String, decodedTo type: T.Type) throws -> T {
    let file = try Resource(name: fileName, type: "json")
    let data = try Data(contentsOf: file.url)
    return try JSONDecoder().decode(type, from: data)
}
