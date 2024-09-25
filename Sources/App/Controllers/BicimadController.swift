import Vapor
import Foundation
import CommonCrypto

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

///getHashcode
struct BikeData: Content {
    let D1: String
    let D2: String
    let BikeNumber: String
    let Docker: String
    let DNI: String
}

struct BicimadController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let bicimad = routes.grouped("bicimad")
        
        bicimad.get("stars", use: getBicimadFavs)
        bicimad.get("rel", use: getBicimadRel)
        bicimad.post("gethashcode", use: getBicimadHashcode)
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
    
    @Sendable
    func getBicimadHashcode(req: Request) throws -> Response {
        let data = try req.content.decode(BikeData.self)
        req.logger.info("Hashcode Requested:\n- D1: \(data.D1)\n- D2: \(data.D2)\n- Bike Nº: \(data.BikeNumber)\n- Docker: \(data.Docker)\n- DNI: \(data.DNI)\n-")
        let (decodedAccessKey, decodedBikeKey) = try decodeKeys(encodedAccessKey: Environment.get("eAK")!, encodedBikeKey: Environment.get("eBK")!)
        let firstCipherStr = generateFirstCipherString(data: data)
        let secondCipherStr = generateSecondCipherString(firstCipherStr: firstCipherStr, decodedBikeKey: decodedBikeKey)
        guard let hashCode = ecbEncryptBase64(src: secondCipherStr.data(using: .utf8)!, key: decodedAccessKey) else {
            throw Abort(.internalServerError, reason: "Encryption failed")
        }
        return Response(body: Response.Body(string: hashCode))
    }
    
    func decodeKeys(encodedAccessKey: String, encodedBikeKey: String) throws -> (String, String) {
        guard let accessKeyData = Data(base64Encoded: encodedAccessKey), let bikeKeyData = Data(base64Encoded: encodedBikeKey)
        else {
            throw Abort(.internalServerError, reason: "Key decoding failed")
        }
        let decodedAccessKey = String(data: accessKeyData, encoding: .utf8)!.uppercased().prefix(8)
        let decodedBikeKey = String(data: bikeKeyData, encoding: .utf8)!

        return (String(decodedAccessKey), decodedBikeKey)
    }
    
    func generateFirstCipherString(data: BikeData) -> String {
        let (d1, d2) = resizeCoordinates(d1: data.D1, d2: data.D2)
        var firstCipherStr = "\(data.BikeNumber)#\(data.Docker)#\(d1)#\(d2)#D#\(data.DNI)"
        
        if firstCipherStr.count % 8 != 0 {
            let length = 8 - (firstCipherStr.count % 8)
            firstCipherStr += String(repeating: "#", count: length)
        }
        return firstCipherStr
    }
    
    func resizeCoordinates(d1: String, d2: String) -> (String, String) {
        let d1Padded = d1.padding(toLength: 10, withPad: "0", startingAt: 0)
        let d2Padded = d2.padding(toLength: 10, withPad: "0", startingAt: 0)
        
        return (String(d1Padded.prefix(10)), String(d2Padded.prefix(10)))
    }
    
    func generateSecondCipherString(firstCipherStr: String, decodedBikeKey: String) -> String {
        guard let cipheredString = ecbEncryptHex(src: firstCipherStr.data(using: .utf8)!, key: decodedBikeKey) else {
            return ""
        }
        
        var secondCipherStr = "B\(cipheredString)"
        
        if secondCipherStr.count % 8 != 0 {
            let length = 8 - (secondCipherStr.count % 8)
            secondCipherStr += String(repeating: "Z", count: length)
        }
        return secondCipherStr
    }
    
    func ecbEncryptHex(src: Data, key: String) -> String? {
        let keyData = key.data(using: .utf8)!
        return ecbEncrypt(src: src, key: keyData)?.map { String(format: "%02hhx", $0) }.joined()
    }

    func ecbEncryptBase64(src: Data, key: String) -> String? {
        let keyData = key.data(using: .utf8)!
        return ecbEncrypt(src: src, key: keyData)?.base64EncodedString()
    }

    func ecbEncrypt(src: Data, key: Data) -> Data? {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: src.count + kCCBlockSizeDES)
        
        let result = key.withUnsafeBytes { keyBytes in
            src.withUnsafeBytes { srcBytes in
                CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmDES), CCOptions(kCCOptionECBMode),
                        keyBytes.baseAddress, kCCKeySizeDES, nil,
                        srcBytes.baseAddress, src.count,
                        &outBytes, outBytes.count, &outLength)
            }
        }
        
        if result == CCCryptorStatus(kCCSuccess) {
            return Data(bytes: outBytes, count: outLength)
        } else {
            return nil
        }
    }
}
