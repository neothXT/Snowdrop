//
//  SnowdropCore.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 11/02/2024.
//

import Foundation
import OSLog

// MARK: Request perform methods

public extension Snowdrop.Core {
    private var logger: Logger { Logger() }
    
    @discardableResult
    func performRequest(
        _ request: URLRequest,
        service: Service
    ) async throws -> (Data?, HTTPURLResponse) {
        let session = getSession(pinningMode: service.pinningMode, urlsExcludedFromPinning: service.urlsExcludedFromPinning)
        var data: Data?
        var urlResponse: URLResponse?
        
        var finalRequest = request
        applyRequestBlocks(service.requestBlocks, for: &finalRequest)
        
        do {
            (data, urlResponse) = try await executeRequest(finalRequest, session: session, service: service)
        } catch {
            throw handleError(error as NSError)
        }
        
        guard var response = urlResponse as? HTTPURLResponse else { throw SnowdropError(type: .failedToMapResponse) }
        try handleNon200Code(from: response, data: data)
        guard var finalData = data else { return (data, response) }
        
        applyResponseBlocks(service.responseBlocks, forData: &finalData, response: &response)
        log(level: .info, message: "Request finished. Response:\n\(String(data: finalData, encoding: .utf8) ?? "")", execute: service.verbose)
        return (finalData, response)
    }
    
    func performRequestAndDecode<T: Codable>(
        _ request: URLRequest,
        service: Service
    ) async throws -> T {
        let (data, _) = try await performRequest(request, service: service)
        
        guard let unwrappedData = data else { throw SnowdropError(type: .unexpectedResponse) }
        
        do {
            let decodedData = try service.decoder.decode(T.self, from: unwrappedData)
            return decodedData
        } catch {
            log(level: .error, message: "Response decoding failed.", execute: service.verbose)
            throw SnowdropError(
                type: .failedToMapResponse,
                details: .init(
                    statusCode: -1,
                    localizedString: error.localizedDescription,
                    ogError: error
                ),
                data: data
            )
        }
    }
    
    func executeRequest(_ request: URLRequest, session: URLSession, service: Service) async throws -> (Data?, URLResponse?) {
        var data: Data?
        var urlResponse: URLResponse?
        let jsonPaths = [".json", ".JSON"].reduce([]) { $0 + Bundle.main.paths(forResourcesOfType: $1, inDirectory: nil) }
        
        if let testJSONDictionary = service.testJSONDictionary,
           let requestUrl = request.url,
           let key = testJSONDictionary.keys.first(where: { service.baseUrl.appendingPathComponent($0).absoluteString == requestUrl.absoluteString }),
           let jsonName = testJSONDictionary[key],
           let jsonPath = jsonPaths.first(where: { $0.hasSuffix(jsonName + ".json") || $0.hasSuffix(jsonName + ".JSON") }),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
            
            data = jsonData
            urlResponse = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (data, urlResponse)
        }
        
        do {
            log(level: .info, message: "Executing request \(request.url?.absoluteString ?? "unknown").", execute: service.verbose)
            (data, urlResponse) = try await session.data(for: request)
            session.finishTasksAndInvalidate()
        } catch {
            log(level: .error, message: "Request failed\n\(handleError(error as NSError))", execute: service.verbose)
            throw handleError(error as NSError)
        }
        
        return (data, urlResponse)
    }
    
    private func handleNon200Code(from response: HTTPURLResponse, data: Data?) throws {
        guard !(200..<300 ~= response.statusCode) else { return }
        throw generateError(from: response, data: data)
    }
    
    private func getSession(pinningMode: PinningMode?, urlsExcludedFromPinning: [String]) -> URLSession {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
        let delegate = SessionDelegate(mode: pinningMode, excludedURLs: urlsExcludedFromPinning)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
    }
    
    private func generateError(from response: HTTPURLResponse, data: Data? = nil) -> Error {
        let errorDetails = SnowdropErrorDetails(
            statusCode: response.statusCode,
            localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode).capitalized,
            headers: response.allHeaderFields
        )
        let SnowdropError = SnowdropError(type: .unexpectedResponse, details: errorDetails, data: data)
        return  SnowdropError
    }
    
    private func handleError(_ error: NSError, data: Data? = nil) -> Error {
        let networkErrorCodes = [
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorCannotLoadFromNetwork,
            NSURLErrorTimedOut
        ]
        
        let errorType: SnowdropError.ErrorType = networkErrorCodes.contains(error.code) ? .noInternetConnection : .unexpectedResponse
        let errorDetails = SnowdropErrorDetails(
            statusCode: error.code,
            localizedString: error.localizedDescription.capitalized
        )
        let SnowdropError = SnowdropError(type: errorType, details: errorDetails, data: data)
        return SnowdropError
    }
}

// MARK: RequestBlock appliance

extension Snowdrop.Core {
    private func applyRequestBlocks(
        _ blocks: [String: RequestHandler],
        for request: inout URLRequest
    ) {
        var pathBlocks = blocks.filter {
            guard let urlString = request.url?.absoluteString,
                  let escapedKey = $0.key.removingPercentEncoding,
                  let regex = try? NSRegularExpression(pattern: escapedKey) else {
                return false
            }
            return regex.matches(in: urlString, range: .init(location: 0, length: urlString.count)).count == 1
        }.values

        if pathBlocks.isEmpty {
            pathBlocks = blocks.filter { $0.key == "all" }.values
        }
        
        pathBlocks.forEach { block in
            request = block(request)
        }
    }
    
    private func applyResponseBlocks(
        _ blocks: [String: ResponseHandler],
        forData data: inout Data,
        response: inout HTTPURLResponse
    ) {
        var pathBlocks = blocks.filter {
            guard let urlString = response.url?.absoluteString,
                  let escapedKey = $0.key.removingPercentEncoding,
                  let regex = try? NSRegularExpression(pattern: escapedKey) else {
                return false
            }
            return regex.matches(in: urlString, range: .init(location: 0, length: urlString.count)).count == 1
        }.values
        
        if pathBlocks.isEmpty {
            pathBlocks = blocks.filter { $0.key == "all" }.values
        }
        
        pathBlocks.forEach { block in
            data = block(data, response)
        }
    }
}

// MARK: Body builing methods

public extension Snowdrop.Core {
    func prepareUrlEncodedBody(data: Any) -> Data? {
        switch data {
        case let data as Data:
            data
        case let data as any Encodable:
            mapToArray(dictionary: data.toDictionary()).joinedWithAmpersands().data(using: .utf8)
        case let data as [String: Any]:
            mapToArray(dictionary: data).joinedWithAmpersands().data(using: .utf8)
        default:
            nil
        }
    }
    
    func prepareBody(data: Any) -> Data? {
        switch data {
        case let data as Data:
            data
        case let data as any Encodable:
            try? data.toJsonData()
        case let data as [String: Any]:
            try? JSONSerialization.data(withJSONObject: data)
        default:
            nil
        }
    }
}

private extension Snowdrop.Core {
    func mapToArray(dictionary: [String: Any]) -> [String] {
        dictionary.reduce([]) {
            guard let value = valueOrNil($1.value) else { return $0 }
            return $0 + ["\($1.key)=\(value)"]
        }
    }
    
    func log(level: OSLogType, message: String, execute: Bool) {
        guard execute else { return }
        logger.log(level: level, "[Snowdrop] \(message)")
    }
}

fileprivate extension Collection where Element == String {
    func joinedWithAmpersands() -> String {
        self.joined(separator: "&")
    }
}
