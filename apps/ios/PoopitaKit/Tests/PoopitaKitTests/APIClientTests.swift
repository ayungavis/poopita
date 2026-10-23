import Foundation
@testable import PoopitaKit
import Testing

private func client(_ server: StubServer) throws -> URLSessionAPIClient {
    try URLSessionAPIClient(baseURL: #require(URL(string: "https://poopita.test")), session: server.session)
}

private struct ProbeRequestDTO: Encodable, Sendable {
    let nonce: String
}

private struct PostProbeEndpoint: RequestEndpoint {
    typealias Response = EmptyResponseDTO

    let request: ProbeRequestDTO

    var path: String {
        "probe"
    }

    var method: HTTPMethod {
        .post
    }
}

struct APIClientTests {
    @Test func aSuccessDecodesTheResponse() async throws {
        let server = StubServer()
        server.stub("/v1/health", .json(#"{"status":"ok"}"#))

        let response = try await client(server).send(GetHealthEndpoint())

        #expect(response.status == "ok")
    }

    @Test func anEndpointPathAppendsToABaseURLThatCarriesAPath() throws {
        let base = try #require(URL(string: "https://api.poopita.test/services"))

        let url = URLSessionAPIClient.url(base: base, endpoint: GetHealthEndpoint())

        #expect(url.absoluteString == "https://api.poopita.test/services/v1/health")
    }

    @Test func aRequestEndpointSendsItsBodyAsJSON() async throws {
        let server = StubServer()
        server.stub("/probe", StubbedReply(status: 204))

        _ = try await client(server).send(PostProbeEndpoint(request: ProbeRequestDTO(nonce: "n1")))

        let sent = try #require(server.sent(to: "/probe").first)
        #expect(sent.contentType == "application/json")
        #expect(String(bytes: sent.body, encoding: .utf8) == #"{"nonce":"n1"}"#)
    }

    @Test func theErrorEnvelopeCodeWinsOverTheStatus() async throws {
        let server = StubServer()
        server.stub("/v1/health", .json(#"{"error":{"code":"not_found"}}"#, status: 400))

        await #expect(throws: AppError.notFound) {
            try await client(server).send(GetHealthEndpoint())
        }
    }

    @Test func theStatusDecidesWhenThereIsNoEnvelope() async throws {
        let server = StubServer()
        server.stub("/v1/health", StubbedReply(status: 429).with(header: "Retry-After", "7"))

        await #expect(throws: AppError.rateLimited(retryAfter: .seconds(7))) {
            try await client(server).send(GetHealthEndpoint())
        }
    }

    @Test func anUndecodableBodyIsServerRejected() async throws {
        let server = StubServer()
        server.stub("/v1/health", .json("not json"))

        await #expect(throws: AppError.serverRejected) {
            try await client(server).send(GetHealthEndpoint())
        }
    }

    @Test func aTransportFailureIsNetwork() async throws {
        let server = StubServer()
        server.fail(with: URLError(.notConnectedToInternet))

        await #expect(throws: AppError.network) {
            try await client(server).send(GetHealthEndpoint())
        }
    }
}
