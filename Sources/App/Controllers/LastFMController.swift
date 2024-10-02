import Vapor
import Foundation

struct LastFMController: RouteCollection {
    let baseURL = "https://ws.audioscrobbler.com/2.0/"
    let recentTracksParams = "method=user.getrecenttracks&limit=1&format=json"
    let timeout: TimeInterval = 10

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
            
            guard let body = response.body,
                  let data = body.getData(at: 0, length: body.readableBytes),
                  let lastfmResponse = try? JSONDecoder().decode(LastFMResponse.self, from: data) else {
                throw Abort(.internalServerError)
            }

            guard let track = lastfmResponse.recenttracks.track.first else {
                return Response(status: .ok, version: req.version, headers: [:], body: .init(string: """
                    {"message": "NO_TRACKS_FOUND"}
                    """))
            }

            let isPlaying = track.attr?.nowplaying == "true"

            if req.query["format"] == "shields.io" {
                let song = track.name
                let artist = track.artist.text
                let includeArtist = (req.query["artist"] ?? "y").lowercased() != "n"
                let message = includeArtist ? "\(song) - \(artist)" : song
                
                return Response(status: .ok, version: req.version, headers: [:], body: .init(string: """
                    {
                        "schemaVersion": 1,
                        "label": "\(isPlaying ? "Listening to" : "Last Played")",
                        "message": "\(message)"
                    }
                    """))
            }

            return Response(status: .ok, version: req.version, headers: [:], body: .init(data: try JSONEncoder().encode(["track": track])))
        } catch {
            req.logger.report(error: error)
            return Response(status: .internalServerError, version: req.version, headers: [:], body: .init(string: """
                {"message": "INTERNAL_ERROR"}
                """))
        }
    }
}

struct LastFMResponse: Codable {
    let recenttracks: RecentTracks
}

struct RecentTracks: Codable {
    let track: [Track]
}

struct Track: Codable {
    let name: String
    let artist: Artist
    let attr: Attr?

    enum CodingKeys: String, CodingKey {
        case name
        case artist
        case attr = "@attr"
    }
}

struct Artist: Codable {
    let text: String

    enum CodingKeys: String, CodingKey {
        case text = "#text"
    }
}

struct Attr: Codable {
    let nowplaying: String
}

