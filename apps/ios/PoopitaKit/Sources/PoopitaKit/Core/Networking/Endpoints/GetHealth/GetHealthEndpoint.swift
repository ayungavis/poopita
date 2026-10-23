/// GET /v1/health
struct GetHealthEndpoint: Endpoint {
    typealias Response = GetHealthResponseDTO

    var path: String {
        "v1/health"
    }
}
