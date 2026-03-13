import Foundation

struct BCRAEnvelopeDTO<Results: Decodable>: Decodable {
    let status: Int
    let metadata: BCRAMetadataDTO?
    let results: Results
    let errorMessages: [String]?
}

struct BCRAMetadataDTO: Decodable {
    let resultset: BCRAResultSetDTO?
}

struct BCRAResultSetDTO: Decodable {
    let count: Int
    let offset: Int
    let limit: Int
}
