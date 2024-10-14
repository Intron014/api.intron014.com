import Vapor

struct emtStations: Content {
    var id: Int
    var name: String
}
struct getEmtFavsResponse: Content {
    var data: [emtStations]
}

struct EMTController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let emt = routes.grouped("emt")
        
        emt.get("stars", use: getEmtStars)
    }

    @Sendable
    func getEmtStars(req: Request) throws -> getEmtFavsResponse {
        let stations = [
            emtStations(id: 3950, name: "Home"),
            emtStations(id: 3847, name: "Home Away"),
            emtStations(id: 5562, name: "UPM Down"),
            emtStations(id: 3854, name: "Metro Las Suertes"),
            emtStations(id: 4112, name: "CC La Gavia"),
            emtStations(id: 2612, name: "UPM Up Up"),
            emtStations(id: 1027, name: "Sierra de Guadalupe"),
            emtStations(id: 0000, name: "Others")
        ]
        return getEmtFavsResponse(data: stations)
    }
}