import Vapor
import Foundation

struct LastFMController: RouteCollection {
    let baseURL = "https://ws.audioscrobbler.com/2.0/"
    let recentTracksParams = "method=user.getrecenttracks&limit=1&format=json"

    func boot(routes: RoutesBuilder) throws {
        routes.get(":user", "latest-song", use: latestSong)
    }

    @Sendable
    func latestSong(req: Request) async throws -> Response {
        let user = req.parameters.get("user") ?? ""
        req.logger.info("Received a request: \(req)")
        req.logger.info("Requester IP: \(req.remoteAddress?.ipAddress ?? "unknown")")

        guard let apiKey = Environment.get("LASTFM_API_KEY") else {
            req.logger.error("Last.fm API key is not set")
            return Response(status: .internalServerError, version: req.version, headers: [:], body: .init(string: """
                {"message": "INTERNAL_ERROR"}
                """))
        }

        let apiURL = "\(baseURL)?\(recentTracksParams)&user=\(user)&api_key=\(apiKey)"

        do {
            let client = req.client
            let response = try await client.get(URI(string: apiURL), headers: [:])
            
            guard var body = response.body,
                  let data = body.readData(length: body.readableBytes),
                  let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let recenttracks = json["recenttracks"] as? [String: Any],
                  let tracks = recenttracks["track"] as? [[String: Any]],
                  let firstTrack = tracks.first else {
                return Response(status: .internalServerError, version: req.version, headers: [:], body: .init(string: """
                    {"message": "INVALID_RESPONSE"}
                    """))
            }
            
            let sortedTrack = sortDictionaryAlphabetically(firstTrack)
            let restructuredJSON = ["track": sortedTrack]
            let sortedJSON = sortDictionaryAlphabetically(restructuredJSON)
            
            let restructuredData = try JSONSerialization.data(withJSONObject: sortedJSON, options: [.sortedKeys])
            
            return Response(status: .ok, version: req.version, headers: ["Content-Type": "application/json"], body: .init(data: restructuredData))
        } catch {
            req.logger.report(error: error)
            return Response(status: .internalServerError, version: req.version, headers: [:], body: .init(string: """
                {"message": "INTERNAL_ERROR"}
                """))
        }
    }
    
    private func sortDictionaryAlphabetically(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for key in dict.keys.sorted() {
            if let nestedDict = dict[key] as? [String: Any] {
                result[key] = sortDictionaryAlphabetically(nestedDict)
            } else if let nestedArray = dict[key] as? [[String: Any]] {
                result[key] = nestedArray.map { sortDictionaryAlphabetically($0) }
            } else {
                result[key] = dict[key]
            }
        }
        return result
    }
}
