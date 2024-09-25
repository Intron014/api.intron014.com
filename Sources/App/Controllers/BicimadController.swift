import Vapor
import Foundation

/// getBicimadFavs
struct bicimadStations: Content {
    var name: String
}
struct getBicimadFavsResponse: Content {
    var data: [bicimadStations]
}

///getBicimadRel
struct BicimadRel: Content {
    var id: Int
    var bid: Int
}
struct getBicimadRelResponse: Content {
    var data: [BicimadRel]
}

struct BicimadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bicimad = routes.grouped("bicimad")
        
        bicimad.get("stars", use: getBicimadFavs)
        bicimad.get("rel", use: getBicimadRel)
    }
    
    @Sendable
    func getBicimadFavs(req: Request) throws -> getBicimadFavsResponse {
        let stations = [
            bicimadStations(name: "451 - Home"),
            bicimadStations(name: "436 - UPM"),
            bicimadStations(name: "437 - Sierra de Guadalupe"),
            bicimadStations(name: "440 - Villa de Vallecas"),
            bicimadStations(name: "000 - Other")
        ]
        return getBicimadFavsResponse(data: stations)
    }
    
    @Sendable
    func getBicimadRel(req: Request) throws -> getBicimadRelResponse {
        let bikerel = [
            BicimadRel(id: 2078, bid: 436),
            BicimadRel(id: 2003, bid: 437),
            BicimadRel(id: 2053, bid: 440),
            BicimadRel(id: 2188, bid: 451)
        ]
        return getBicimadRelResponse(data: bikerel)
    }
    
    
}
