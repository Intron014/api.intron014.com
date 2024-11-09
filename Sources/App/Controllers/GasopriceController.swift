import Vapor

struct GasStation: Content {
    enum CodingKeys: String, CodingKey {
        case bioEthanolPercentage = "% BioEtanol"
        case esterMetilicoPercentage = "% Éster metílico"
        case postalCode = "C.P."
        case address = "Dirección"
        case schedule = "Horario"
        case idCCAA = "IDCCAA"
        case idEESS = "IDEESS"
        case idMunicipio = "IDMunicipio"
        case idProvincia = "IDProvincia"
        case latitude = "Latitud"
        case locality = "Localidad"
        case longitude = "Longitud (WGS84)"
        case margin = "Margen"
        case municipality = "Municipio"
        case priceBiodiesel = "Precio Biodiesel"
        case priceBioethanol = "Precio Bioetanol"
        case priceNaturalGasCompressed = "Precio Gas Natural Comprimido"
        case priceNaturalGasLiquefied = "Precio Gas Natural Licuado"
        case priceLPG = "Precio Gases licuados del petróleo"
        case priceDieselA = "Precio Gasoleo A"
        case priceDieselB = "Precio Gasoleo B"
        case priceDieselPremium = "Precio Gasoleo Premium"
        case priceGasoline95E10 = "Precio Gasolina 95 E10"
        case priceGasoline95E5 = "Precio Gasolina 95 E5"
        case priceGasoline95E5Premium = "Precio Gasolina 95 E5 Premium"
        case priceGasoline98E10 = "Precio Gasolina 98 E10"
        case priceGasoline98E5 = "Precio Gasolina 98 E5"
        case priceHydrogen = "Precio Hidrogeno"
        case province = "Provincia"
        case remission = "Remisión"
        case label = "Rótulo"
        case saleType = "Tipo Venta"
    }
    
    var bioEthanolPercentage: String
    var esterMetilicoPercentage: String
    var postalCode: String
    var address: String
    var schedule: String
    var idCCAA: String
    var idEESS: String
    var idMunicipio: String
    var idProvincia: String
    var latitude: String
    var locality: String
    var longitude: String 
    var margin: String
    var municipality: String
    var priceBiodiesel: String
    var priceBioethanol: String
    var priceNaturalGasCompressed: String
    var priceNaturalGasLiquefied: String
    var priceLPG: String
    var priceDieselA: String
    var priceDieselB: String
    var priceDieselPremium: String
    var priceGasoline95E10: String
    var priceGasoline95E5: String
    var priceGasoline95E5Premium: String 
    var priceGasoline98E10: String
    var priceGasoline98E5: String
    var priceHydrogen: String
    var province: String
    var remission: String
    var label: String
    var saleType: String
}

struct GasopriceResponse: Content {
    enum CodingKeys: String, CodingKey {
        case date = "Fecha"
        case stations = "ListaEESSPrecio"
        case note = "Nota"
        case result = "ResultadoConsulta"
    }
    
    let date: String
    let stations: [GasStation]
    let note: String
    let result: String
}

struct GasopriceController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let gasoprice = routes.grouped("gasoprice")

        gasoprice.get("stats", use: getFuelStats)
        gasoprice.get("prom-stats", use: getPrometheusStats)
    }

    private func isCurrentlyOpen(schedule: String, currentDate: Date) -> Bool {
        let calendar = Calendar.current
        let logger = Logger(label: "com.api.intron014.gasoprice")
        let shouldLog = false
        
        if shouldLog { logger.info("Schedule input: '\(schedule)'") }
        if shouldLog { logger.info("Current date: '\(currentDate)'") }
        
        var weekday = calendar.component(.weekday, from: currentDate)
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)
        let currentMinutes = hour * 60 + minute
        
        weekday = weekday == 1 ? 7 : weekday - 1
        if shouldLog { logger.info("Current weekday (1=Mon, 7=Sun): \(weekday)") }
        
        let cleanSchedule = schedule
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        
        let scheduleRanges = cleanSchedule
            .components(separatedBy: ";")
            .flatMap { $0.components(separatedBy: "Y") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            
        if shouldLog { logger.info("Schedule ranges found: \(scheduleRanges)") }
        
        for range in scheduleRanges {
            guard let colonIndex = range.firstIndex(of: ":"),
                  range.distance(from: range.startIndex, to: colonIndex) > 0 else {
                logger.warning("Invalid schedule format: \(range)")
                continue
            }
            
            let days = String(range[..<colonIndex])
            let hours = String(range[range.index(after: colonIndex)...])
            if shouldLog { logger.info("Days: '\(days)', Hours: '\(hours)'") }
            
            let isMatchingDay: Bool
            if days.contains("-") {
                let dayRange = days.components(separatedBy: "-")
                if dayRange.count == 2 {
                    let startDay = getDayNumber(String(dayRange[0]))
                    let endDay = getDayNumber(String(dayRange[1]))
                    isMatchingDay = weekday >= startDay && weekday <= endDay
                    if shouldLog { logger.info("Day range: \(startDay)-\(endDay), current: \(weekday), matches: \(isMatchingDay)") }
                } else {
                    isMatchingDay = false
                    if shouldLog { logger.warning("Invalid day range: \(days)") }
                }
            } else {
                isMatchingDay = days.contains(getDayLetter(weekday))
                if shouldLog { logger.info("Single day check: '\(days)' contains '\(getDayLetter(weekday))': \(isMatchingDay)") }
            }
            
            if isMatchingDay {
                let timeRange = hours.components(separatedBy: "-")
                guard timeRange.count == 2 else {
                    logger.warning("Invalid time range: \(hours)")
                    continue
                }
                
                let startTime = timeRange[0].components(separatedBy: ":")
                let endTime = timeRange[1].components(separatedBy: ":")
                
                guard let startHour = Int(startTime[0]),
                      let startMinute = startTime.count > 1 ? Int(startTime[1]) : 0,
                      let endHour = Int(endTime[0]),
                      let endMinute = endTime.count > 1 ? Int(endTime[1]) : 0 else {
                    logger.warning("Could not parse time components")
                    continue
                }
                
                let startMinutes = startHour * 60 + startMinute
                let endMinutes = endHour * 60 + endMinute
                
                if shouldLog { logger.info("Time check: \(startMinutes) <= \(currentMinutes) <= \(endMinutes)") }
                
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    if shouldLog { logger.info("Station is open!") }
                    return true
                }
            }
        }
        
        if shouldLog { logger.info("Station is closed") }
        return false
    }

    private func getDayNumber(_ day: String) -> Int {
        switch day.uppercased() {
        case "L": return 1
        case "M": return 2
        case "X": return 3
        case "J": return 4
        case "V": return 5
        case "S": return 6
        case "D": return 7
        default: return 0
        }
    }

    private func getDayLetter(_ day: Int) -> String {
        switch day {
        case 1: return "L"
        case 2: return "M"
        case 3: return "X"
        case 4: return "J"
        case 5: return "V"
        case 6: return "S"
        case 7: return "D"
        default: return ""
        }
    }

    private func categorizeSchedule(_ schedule: String, date: String) -> String {
        if schedule.contains("24H") {
            return "24H"
        } else if schedule.lowercased().contains("cerrado") {
            return "closed"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "es_ES")
            
            guard let currentDate = dateFormatter.date(from: date) else {
                return "unknown"
            }
            
            return isCurrentlyOpen(schedule: schedule, currentDate: currentDate) ? "open" : "closed"
        }
    }

    private func getProvincePriceStats(_ stations: [GasStation]) -> [String: [String: [String: Double]]] {
        let fuelTypes = [
            "dieselA": { (station: GasStation) -> String in station.priceDieselA },
            "dieselB": { (station: GasStation) -> String in station.priceDieselB },
            "dieselPremium": { (station: GasStation) -> String in station.priceDieselPremium },
            "gasoline95E5": { (station: GasStation) -> String in station.priceGasoline95E5 },
            "gasoline95E10": { (station: GasStation) -> String in station.priceGasoline95E10 },
            "gasoline95E5Premium": { (station: GasStation) -> String in station.priceGasoline95E5Premium },
            "gasoline98E5": { (station: GasStation) -> String in station.priceGasoline98E5 },
            "gasoline98E10": { (station: GasStation) -> String in station.priceGasoline98E10 },
            "biodiesel": { (station: GasStation) -> String in station.priceBiodiesel },
            "bioethanol": { (station: GasStation) -> String in station.priceBioethanol },
            "naturalGasCompressed": { (station: GasStation) -> String in station.priceNaturalGasCompressed },
            "naturalGasLiquefied": { (station: GasStation) -> String in station.priceNaturalGasLiquefied },
            "lpg": { (station: GasStation) -> String in station.priceLPG },
            "hydrogen": { (station: GasStation) -> String in station.priceHydrogen }
        ]

        let provinceStats = Dictionary(grouping: stations) { $0.province }
        var result: [String: [String: [String: Double]]] = [:]

        for (province, provinceStations) in provinceStats {
            var fuelStats: [String: [String: Double]] = [:]
            
            for (fuelType, priceExtractor) in fuelTypes {
                let prices = provinceStations
                    .map(priceExtractor)
                    .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
                    .filter { $0 > 0 }
                
                if !prices.isEmpty {
                    fuelStats[fuelType] = [
                        "min": prices.min() ?? 0,
                        "max": prices.max() ?? 0,
                        "avg": prices.average(),
                        "count": Double(prices.count)
                    ]
                }
            }
            
            result[province] = fuelStats
        }
        
        return result
    }

    @Sendable
    func getFuelStats(req: Request) async throws -> Response {
        let url = "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/"
        let response = try await req.client.get(URI(string: url))
        let gasopriceResponse = try response.content.decode(GasopriceResponse.self)
        
        var stats: [String: Any] = [:]
        
        stats["totalStations"] = gasopriceResponse.stations.count
        
        let fuelTypes = [
            "dieselA": { (station: GasStation) -> String in station.priceDieselA },
            "dieselB": { (station: GasStation) -> String in station.priceDieselB },
            "dieselPremium": { (station: GasStation) -> String in station.priceDieselPremium },
            "gasoline95E5": { (station: GasStation) -> String in station.priceGasoline95E5 },
            "gasoline95E10": { (station: GasStation) -> String in station.priceGasoline95E10 },
            "gasoline95E5Premium": { (station: GasStation) -> String in station.priceGasoline95E5Premium },
            "gasoline98E5": { (station: GasStation) -> String in station.priceGasoline98E5 },
            "gasoline98E10": { (station: GasStation) -> String in station.priceGasoline98E10 },
            "biodiesel": { (station: GasStation) -> String in station.priceBiodiesel },
            "bioethanol": { (station: GasStation) -> String in station.priceBioethanol },
            "naturalGasCompressed": { (station: GasStation) -> String in station.priceNaturalGasCompressed },
            "naturalGasLiquefied": { (station: GasStation) -> String in station.priceNaturalGasLiquefied },
            "lpg": { (station: GasStation) -> String in station.priceLPG },
            "hydrogen": { (station: GasStation) -> String in station.priceHydrogen }
        ]
        
        var priceStats: [String: [String: Double]] = [:]
        
        for (fuelType, priceExtractor) in fuelTypes {
            let prices = gasopriceResponse.stations
                .map(priceExtractor)
                .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
                .filter { $0 > 0 }
            
            if !prices.isEmpty {
                priceStats[fuelType] = [
                    "min": prices.min() ?? 0,
                    "max": prices.max() ?? 0,
                    "avg": prices.average(),
                    "count": Double(prices.count)
                ]
            }
        }
        
        stats["priceStats"] = priceStats
        
        let provinceStats = Dictionary(grouping: gasopriceResponse.stations) { $0.province }
            .mapValues { $0.count }
        stats["stationsByProvince"] = provinceStats
        
        let schedules = Dictionary(grouping: gasopriceResponse.stations) { 
            categorizeSchedule($0.schedule, date: gasopriceResponse.date)
        }
        .mapValues { $0.count }
        stats["scheduleTypes"] = schedules
        
        let serviceTypes = Dictionary(grouping: gasopriceResponse.stations) { $0.saleType }
            .mapValues { $0.count }
        stats["serviceTypes"] = serviceTypes
        
        let initialBrandCount = Dictionary(grouping: gasopriceResponse.stations) { station -> String in 
            station.label.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .mapValues { $0.count }
        
        let significantBrands = initialBrandCount.filter { $0.value >= 30 }
        
        let brands = Dictionary(grouping: gasopriceResponse.stations) { station -> String in
            let label = station.label.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return significantBrands.keys.contains(label) ? label : "OTHERS"
        }
        .mapValues { $0.count }
        
        stats["brandDistribution"] = brands

        let margins = Dictionary(grouping: gasopriceResponse.stations) { $0.margin }
            .mapValues { $0.count }
        stats["marginDistribution"] = margins
        
        stats["lastUpdate"] = gasopriceResponse.date
        
        // Add province price statistics
        stats["provincesPriceStats"] = getProvincePriceStats(gasopriceResponse.stations)
        
        return try Response(
            status: .ok,
            headers: ["Content-Type": "application/json"],
            body: .init(data: JSONSerialization.data(withJSONObject: stats))
        )
    }

    @Sendable
    private func getPrometheusStats(req: Request) async throws -> Response {
        let url = "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/"
        let response = try await req.client.get(URI(string: url))
        let gasopriceResponse = try response.content.decode(GasopriceResponse.self)
        
        var metrics: String = ""

        metrics += "# HELP gas_station_total_total Total number of stations\n"
        metrics += "# TYPE gas_station_total_total gauge\n"
        metrics += "gas_station_total_total \(gasopriceResponse.stations.count)\n"
        
        let fuelTypes = [
            ("dieselA", { (station: GasStation) -> String in station.priceDieselA }),
            ("dieselB", { (station: GasStation) -> String in station.priceDieselB }),
            ("dieselPremium", { (station: GasStation) -> String in station.priceDieselPremium }),
            ("gasoline95E5", { (station: GasStation) -> String in station.priceGasoline95E5 }),
            ("gasoline95E10", { (station: GasStation) -> String in station.priceGasoline95E10 }),
            ("gasoline95E5Premium", { (station: GasStation) -> String in station.priceGasoline95E5Premium }),
            ("gasoline98E5", { (station: GasStation) -> String in station.priceGasoline98E5 }),
            ("gasoline98E10", { (station: GasStation) -> String in station.priceGasoline98E10 }),
            ("biodiesel", { (station: GasStation) -> String in station.priceBiodiesel }),
            ("bioethanol", { (station: GasStation) -> String in station.priceBioethanol }),
            ("naturalGasCompressed", { (station: GasStation) -> String in station.priceNaturalGasCompressed }),
            ("naturalGasLiquefied", { (station: GasStation) -> String in station.priceNaturalGasLiquefied }),
            ("lpg", { (station: GasStation) -> String in station.priceLPG }),
            ("hydrogen", { (station: GasStation) -> String in station.priceHydrogen })
        ]
        
        for (fuelType, priceExtractor) in fuelTypes {
            let prices = gasopriceResponse.stations
                .map(priceExtractor)
                .compactMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
                .filter { $0 > 0 }
            
            if !prices.isEmpty {
                let minPrice = prices.min() ?? 0
                let maxPrice = prices.max() ?? 0
                let avgPrice = prices.average()
                
                metrics += "# HELP gas_station_price_\(fuelType)_min Minimum price of \(fuelType)\n"
                metrics += "# TYPE gas_station_price_\(fuelType)_min gauge\n"
                metrics += "gas_station_price_\(fuelType)_min \(minPrice)\n"
                
                metrics += "# HELP gas_station_price_\(fuelType)_max Maximum price of \(fuelType)\n"
                metrics += "# TYPE gas_station_price_\(fuelType)_max gauge\n"
                metrics += "gas_station_price_\(fuelType)_max \(maxPrice)\n"
                
                metrics += "# HELP gas_station_price_\(fuelType)_avg Average price of \(fuelType)\n"
                metrics += "# TYPE gas_station_price_\(fuelType)_avg gauge\n"
                metrics += "gas_station_price_\(fuelType)_avg \(avgPrice)\n"
                
                metrics += "# HELP gas_station_price_\(fuelType)_count Count of \(fuelType) prices\n"
                metrics += "# TYPE gas_station_price_\(fuelType)_count gauge\n"
                metrics += "gas_station_price_\(fuelType)_count \(prices.count)\n"
            }
        }
        
        let provinceStats = Dictionary(grouping: gasopriceResponse.stations) { $0.province }
        for (province, stations) in provinceStats {
            let provincen = province
            .replacingOccurrences(of: "Á", with: "A")
            .replacingOccurrences(of: "É", with: "E")
            .replacingOccurrences(of: "Í", with: "I")
            .replacingOccurrences(of: "Ó", with: "O")
            .replacingOccurrences(of: "Ú", with: "U")
            .replacingOccurrences(of: "Ñ", with: "N")
            .replacingOccurrences(of: "Ç", with: "C")
            .replacingOccurrences(of: "è", with: "e")
            metrics += "# HELP gas_station_count_by_province_count Number of stations in province \(provincen)\n"
            metrics += "# TYPE gas_station_count_by_province_count gauge\n"
            metrics += "gas_station_count_by_province_count{province=\"\(provincen)\"} \(stations.count)\n"
        }
        
        let schedules = Dictionary(grouping: gasopriceResponse.stations) { 
            categorizeSchedule($0.schedule, date: gasopriceResponse.date)
        }
        for (scheduleType, stations) in schedules {
            metrics += "# HELP gas_station_schedule_type_count Number of stations with schedule type \(scheduleType)\n"
            metrics += "# TYPE gas_station_schedule_type_count gauge\n"
            metrics += "gas_station_schedule_type_count{schedule_type=\"\(scheduleType)\"} \(stations.count)\n"
        }
        
        let saleTypes = Dictionary(grouping: gasopriceResponse.stations) { $0.saleType }
        for (saleType, stations) in saleTypes {
            metrics += "# HELP gas_station_sale_type_count Number of stations with sale type \(saleType)\n"
            metrics += "# TYPE gas_station_sale_type_count gauge\n"
            metrics += "gas_station_sale_type_count{sale_type=\"\(saleType)\"} \(stations.count)\n"
        }
        
        let initialBrandCount = Dictionary(grouping: gasopriceResponse.stations) { station -> String in 
            station.label.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .mapValues { $0.count }
        
        let significantBrands = initialBrandCount.filter { $0.value >= 30 }
        
        for (brand, count) in significantBrands {
            metrics += "# HELP gas_station_brand_distribution_count Distribution of stations by brand \(brand)\n"
            metrics += "# TYPE gas_station_brand_distribution_count gauge\n"
            metrics += "gas_station_brand_distribution_count{brand=\"\(brand)\"} \(count)\n"
        }
        
        let marginStats = Dictionary(grouping: gasopriceResponse.stations) { $0.margin }
        for (margin, stations) in marginStats {
            metrics += "# HELP gas_station_margin_distribution_count Distribution of stations by margin \(margin)\n"
            metrics += "# TYPE gas_station_margin_distribution_count gauge\n"
            metrics += "gas_station_margin_distribution_count{margin=\"\(margin)\"} \(stations.count)\n"
        }
        
        // Add province price metrics
        let provincePriceStats = getProvincePriceStats(gasopriceResponse.stations)
        for (province, fuelStats) in provincePriceStats {
            let provinceName = province
                .replacingOccurrences(of: "Á", with: "A")
                .replacingOccurrences(of: "É", with: "E")
                .replacingOccurrences(of: "Í", with: "I")
                .replacingOccurrences(of: "Ó", with: "O")
                .replacingOccurrences(of: "Ú", with: "U")
                .replacingOccurrences(of: "Ñ", with: "N")
                .replacingOccurrences(of: "Ç", with: "C")
                .replacingOccurrences(of: "è", with: "e")

            for (fuelType, stats) in fuelStats {
                metrics += "# HELP gas_station_province_price_\(fuelType) Price statistics for \(fuelType) in \(provinceName)\n"
                metrics += "# TYPE gas_station_province_price_\(fuelType) gauge\n"
                metrics += "gas_station_province_price_\(fuelType){province=\"\(provinceName)\",type=\"min\"} \(stats["min"] ?? 0)\n"
                metrics += "gas_station_province_price_\(fuelType){province=\"\(provinceName)\",type=\"max\"} \(stats["max"] ?? 0)\n"
                metrics += "gas_station_province_price_\(fuelType){province=\"\(provinceName)\",type=\"avg\"} \(stats["avg"] ?? 0)\n"
                metrics += "gas_station_province_price_\(fuelType){province=\"\(provinceName)\",type=\"count\"} \(stats["count"] ?? 0)\n"
            }
        }
        
        metrics += "# HELP gas_station_last_update Last update timestamp for gas stations\n"
        metrics += "# TYPE gas_station_last_update gauge\n"
        metrics += "gas_station_last_update \(Date().timeIntervalSince1970)\n"
        
        return Response(
            status: .ok,
            headers: ["Content-Type": "text/plain"],
            body: .init(string: metrics)
        )
    }
}

extension Collection where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0.0 }
        let sum = reduce(0, +)
        return sum / Double(count)
    }
}
