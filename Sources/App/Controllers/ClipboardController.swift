import Vapor

struct LinkRequest: Content {
    let link: String
}

struct ClipboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("modify-clipboard-link", use: modifyClipboardLink)
    }
    
    @Sendable
    func modifyClipboardLink(req: Request) async throws -> LinkRequest {
        do {
            let linkData = try req.content.decode(LinkRequest.self)
            let modifiedLink = linkData.link.replacingOccurrences(of: "?forcedownload=1", with: "?forcedownload=0")
            
            req.logger.info("mod: \(modifiedLink)")
            
            return LinkRequest(link: modifiedLink)
        } catch {
            req.logger.error("Error processing request: \(error)")
            throw Abort(.internalServerError)
        }
    }
}
