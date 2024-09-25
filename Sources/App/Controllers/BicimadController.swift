import Vapor
import Foundation

struct EMTStations: Content {
    var name: String
}
struct getEMTFavsResponse: Content {
    var data: [EMTStations]
}

struct BicimadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bicimad = routes.grouped("bicimad")
        
        bicimad.get("emt-stars", use: getEMTFavs)
    }
    
    @Sendable
    func getEMTFavs(req: Request) throws -> getEMTFavsResponse {
        let stations = [
            EMTStations(name: "451 - Home"),
            EMTStations(name: "436 - UPM"),
            EMTStations(name: "437 - Sierra de Guadalupe"),
            EMTStations(name: "440 - Villa de Vallecas"),
            EMTStations(name: "000 - Other")
        ]
        return getEMTFavsResponse(data: stations)
    }
    
    
    
}
