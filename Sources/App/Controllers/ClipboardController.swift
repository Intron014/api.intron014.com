import Vapor

struct LinkRequest: Content {
    let link: String
}

struct ClipboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("modify-clipboard-link", use: modifyClipboardLink)
    }
    
    @Sendable
    func modifyClipboardLink(req: Request) async throws -> Response {
        do {
            let linkData = try req.content.decode(LinkRequest.self)
            let modifiedLink = linkData.link.replacingOccurrences(of: "?forcedownload=1", with: "?forcedownload=0")
            
            req.logger.info("mod: \(modifiedLink)")
            
            let jsonResponse = Response(status: .ok)
            try jsonResponse.content.encode(LinkRequest(link: modifiedLink))
            jsonResponse.headers.contentType = .json
            
            return jsonResponse
        } catch {
            req.logger.error("Error processing request: \(error)")
            throw Abort(.internalServerError)
        }
    }
}
