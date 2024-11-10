import Vapor
import Foundation
// import Crypto

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
        // bicimad.post("gethashcode", use: getBicimadHashcode)
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
    
    // @Sendable
    // func getBicimadHashcode(req: Request) throws -> Response {
    //     let startTime = Date()
    //     
    //     let data = try req.content.decode(BikeData.self)
    //     req.logger.info("Hashcode Requested:\n- D1: \(data.D1)\n- D2: \(data.D2)\n- Bike Nº: \(data.BikeNumber)\n- Docker: \(data.Docker)\n- DNI: \(data.DNI)\n-")
    //     let (decodedAccessKey, decodedBikeKey) = try decodeKeys(encodedAccessKey: Environment.get("eAK")!, encodedBikeKey: Environment.get("eBK")!, req: req)
    //     let firstCipherStr = generateFirstCipherString(data: data, req: req)
    //     let secondCipherStr = try generateSecondCipherString(firstCipherStr: firstCipherStr, decodedBikeKey: decodedBikeKey, req: req)
    //     guard let hashCode = ecbEncryptBase64(src: secondCipherStr.data(using: .utf8)!, key: decodedAccessKey) else {
    //         throw Abort(.internalServerError, reason: "Encryption failed")
    //     }
    //     
    //     let endTime = Date()
    //     let timeInterval = endTime.timeIntervalSince(startTime)
    //     req.logger.info("Hashcode Generated: \(hashCode)\n in \(timeInterval) seconds")
    //     
    //     return Response(body: Response.Body(string: hashCode))
    // }
    
    // func decodeKeys(encodedAccessKey: String, encodedBikeKey: String, req: Request) throws -> (String, String) {
    //     guard let accessKeyData = Data(base64Encoded: encodedAccessKey), let bikeKeyData = Data(base64Encoded: encodedBikeKey)
    //     else {
    //         throw Abort(.internalServerError, reason: "Key decoding failed")
    //     }
    //     let decodedAccessKey = String(data: accessKeyData, encoding: .utf8)!.uppercased().prefix(8)
    //     let decodedBikeKey = String(data: bikeKeyData, encoding: .utf8)!
    //     req.logger.info("Keys Decoded:\n- Access Key: \(decodedAccessKey)\n- Bike Key: \(decodedBikeKey)\n-")
    //     return (String(decodedAccessKey), String(decodedBikeKey))
    // }
    
    // func generateFirstCipherString(data: BikeData, req: Request) -> String {
    //     let (d1, d2) = resizeCoordinates(d1: data.D1, d2: data.D2, req: req)
    //     var firstCipherStr = "\(data.BikeNumber)#\(data.Docker)#\(d1)#\(d2)#D#\(data.DNI)"
    //     
    //     if firstCipherStr.count % 8 != 0 {
    //         let length = 8 - (firstCipherStr.count % 8)
    //         firstCipherStr += String(repeating: "#", count: length)
    //     }
    //     req.logger.info("First Cipher String: \(firstCipherStr)")
    //     return firstCipherStr
    // }
    
    // func resizeCoordinates(d1: String, d2: String, req: Request) -> (String, String) {
    //     let d1Padded = d1.padding(toLength: 10, withPad: "0", startingAt: 0)
    //     let d2Padded = d2.padding(toLength: 10, withPad: "0", startingAt: 0)
    //     req.logger.info("Coordinates Resized:\n- D1: \(d1Padded)\n- D2: \(d2Padded)\n-")
    //     return (String(d1Padded.prefix(10)), String(d2Padded.prefix(10)))
    // }

    // func generateSecondCipherString(firstCipherStr: String, decodedBikeKey: String, req: Request) throws -> String {
    //     guard let cipheredString = ecbEncryptHex(src: firstCipherStr.data(using: .utf8)!, key: decodedBikeKey, req: req) else {
    //         throw Abort(.internalServerError, reason: "Second encryption failed")
    //     }
    //     
    //     var secondCipherStr = "B\(cipheredString)"
    //     
    //     if secondCipherStr.count % 8 != 0 {
    //         let length = 8 - (secondCipherStr.count % 8)
    //         secondCipherStr += String(repeating: "Z", count: length)
    //     }
    //     req.logger.info("Second Cipher String: \(secondCipherStr)")
    //     return secondCipherStr
    // }
    
    //func ecbEncryptHex(src: Data, key: String, req: Request) -> String? {
    //    let keyData = key.data(using: .utf8)!
    //    return ecbEncrypt(src: src, key: keyData)?.map { String(format: "%02hhx", $0) }.joined()
    //}


    // func ecbEncryptBase64(src: Data, key: String) -> String? {
    //     let keyData = key.data(using: .utf8)!
    //     return ecbEncrypt(src: src, key: keyData)?.base64EncodedString()
    // }

    // func ecbEncrypt(src: Data, key: Data) -> Data? {
    //     guard key.count == 8 else {
    //         print("Key must be exactly 8 bytes long")
    //         return nil
    //     }
    //     
    //     let paddedKey = key + key
    //     let aesKey = SymmetricKey(data: paddedKey)
    //     let paddedSrc = pkcs7Pad(data: src, blockSize: 8)
    //     var encrypted = Data()
    //     
    //     for i in stride(from: 0, to: paddedSrc.count, by: 8) {
    //         let block = paddedSrc.subdata(in: i..<i+8)
    //         
    //         let paddedBlock = block + block
    //         
    //         do {
    //             let sealedBox = try AES.GCM.seal(paddedBlock, using: aesKey)
    //             encrypted += sealedBox.ciphertext.prefix(8)
    //         } catch {
    //             print("Encryption failed: \(error)")
    //         return nil
    //         }
    //     }
    //     
    //     return encrypted
    // }

    // func pkcs7Pad(data: Data, blockSize: Int) -> Data {
    //     let padding = blockSize - (data.count % blockSize)
    //     var result = data
    //     result += Data(repeating: UInt8(padding), count: padding)
    //     return result
    // }
}
