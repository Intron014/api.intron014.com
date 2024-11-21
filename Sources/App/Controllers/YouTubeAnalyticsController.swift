import Vapor

struct YouTubeVideoData: Content {
    let header: String
    let title: String
    let titleUrl: String
    let subtitles: [Subtitle]
    let time: Date
    let products: [String]
    let activityControls: [String]
    
    struct Subtitle: Content {
        let name: String
        let url: String
    }
}

struct VideoResource: Content {
    let kind: String
    let etag: String
    let items: [Item]
    let pageInfo: PageInfo

    struct Item: Content {
        let kind: String
        let etag: String
        let id: String
        let contentDetails: ContentDetails

        struct ContentDetails: Content {
            let duration: String
            let dimension: String
            let definition: String
            let caption: String
            let licensedContent: Bool
            let contentRating: [String: String]
            let projection: String
        }
    }

    struct PageInfo: Content {
        let totalResults: Int
        let resultsPerPage: Int
    }
}

struct VideoAnalytics: Content {
    let totalVideos: Int
    let totalWatchTime: String
    let videos: [VideoDetail]
    
    struct VideoDetail: Content {
        let title: String
        let channelName: String
        let duration: String
        let watchTime: Int 
    }
}

struct YouTubeAnalyticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let youtube = routes.grouped("youtube")
        youtube.post("upload", use: handleUpload)
    }
    
    @Sendable
    func handleUpload(req: Request) async throws -> VideoAnalytics {
        let videosData = try req.content.decode([YouTubeVideoData].self)
        var videoDetails: [VideoAnalytics.VideoDetail] = []
        var totalSeconds = 0
        
        for videoData in videosData {
            if let videoID = extractVideoID(from: videoData.titleUrl) {
                let videoResource = try await fetchVideoResource(for: videoID, on: req)
                if let duration = videoResource.items.first?.contentDetails.duration {
                    let seconds = parseDuration(duration)
                    totalSeconds += seconds
                    videoDetails.append(.init(
                        title: videoData.title,
                        channelName: videoData.subtitles.first?.name ?? "Unknown",
                        duration: duration,
                        watchTime: seconds
                    ))
                }
            }
        }
        
        return VideoAnalytics(
            totalVideos: videoDetails.count,
            totalWatchTime: formatDuration(seconds: totalSeconds),
            videos: videoDetails
        )
    }
    
    private func parseDuration(_ duration: String) -> Int {
        var seconds = 0
        let scanner = Scanner(string: String(duration.dropFirst()))
        
        while !scanner.isAtEnd {
            var number = 0
            scanner.scanInt(&number)
            if scanner.scanString("H") != nil { seconds += number * 3600 }
            else if scanner.scanString("M") != nil { seconds += number * 60 }
            else if scanner.scanString("S") != nil { seconds += number }
        }
        
        return seconds
    }
    
    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return "\(hours)h \(minutes)m \(remainingSeconds)s"
    }

    private func fetchVideoResource(for videoID: String, on req: Request) async throws -> VideoResource {
        guard let apiKey = Environment.get("YOUTUBE_API_KEY") else {
            throw Abort(.internalServerError, reason: "YouTube API key is not set")
        }
        let url = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoID)&key=\(apiKey)"
        let response = try await req.client.get(URI(string: url))
        return try response.content.decode(VideoResource.self)
    }

    private func extractVideoID(from url: String) -> String? {
        let pattern = "v=([a-zA-Z0-9_-]{11})"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = url as NSString
        let results = regex?.matches(in: url, options: [], range: NSRange(location: 0, length: nsString.length))
        return results?.first.map { nsString.substring(with: $0.range(at: 1)) }
    }

}
