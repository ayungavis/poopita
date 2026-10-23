struct ErrorEnvelopeDTO: Decodable, Sendable {
    let error: ErrorBodyDTO
}

struct ErrorBodyDTO: Decodable, Sendable {
    let code: String
}
