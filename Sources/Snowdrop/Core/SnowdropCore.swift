//
//  SnowdropCore.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 11/02/2024.
//

import Foundation

// MARK: Request perform methods

public extension Snowdrop.Core {
    @discardableResult
    func performRequest(
        _ request: URLRequest,
        baseUrl: URL,
        pinning: PinningMode?,
        urlsExcludedFromPinning: [String],
        requestBlocks: [String: RequestHandler],
        responseBlocks: [String: ResponseHandler],
        testJSONDictionary: [String: String]?
    ) async throws -> (Data?, HTTPURLResponse) {
        let session = getSession(pinningMode: pinning, urlsExcludedFromPinning: urlsExcludedFromPinning)
        var data: Data?
        var urlResponse: URLResponse?
        
        var finalRequest = request
        applyRequestBlocks(requestBlocks, for: &finalRequest)
        
        do {
            (data, urlResponse) = try await executeRequest(baseUrl: baseUrl, session: session, request: finalRequest, testJSONDictionary: testJSONDictionary)
            session.finishTasksAndInvalidate()
        } catch {
            throw handleError(error as NSError)
        }
        
        guard var response = urlResponse as? HTTPURLResponse else { throw SnowdropError(type: .failedToMapResponse) }
        try handleNon200Code(from: response, data: data)
        guard var finalData = data else { return (data, response) }
        
        applyResponseBlocks(responseBlocks, forData: &finalData, response: &response)
        return (finalData, response)
    }
    
    func performRequestAndDecode<T: Codable>(
        _ request: URLRequest,
        baseUrl: URL,
        decoder: JSONDecoder,
        pinning: PinningMode?,
        urlsExcludedFromPinning: [String],
        requestBlocks: [String: RequestHandler],
        responseBlocks: [String: ResponseHandler],
        testJSONDictionary: [String: String]?
    ) async throws -> T {
        let (data, _) = try await performRequest(
            request,
            baseUrl: baseUrl,
            pinning: pinning,
            urlsExcludedFromPinning: urlsExcludedFromPinning,
            requestBlocks: requestBlocks,
            responseBlocks: responseBlocks,
            testJSONDictionary: testJSONDictionary
        )
        
        guard let unwrappedData = data else { throw SnowdropError(type: .unexpectedResponse) }
        
        do {
            let decodedData = try decoder.decode(T.self, from: unwrappedData)
            return decodedData
        } catch {
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
    
    func executeRequest(baseUrl: URL, session: URLSession, request: URLRequest, testJSONDictionary: [String: String]?) async throws -> (Data?, URLResponse?) {
        var data: Data?
        var urlResponse: URLResponse?
        let jsonPaths = [".json", ".JSON"].reduce([]) { $0 + Bundle.main.paths(forResourcesOfType: $1, inDirectory: nil) }
        
        if let testJSONDictionary,
           let requestUrl = request.url,
           let key = testJSONDictionary.keys.first(where: { baseUrl.appendingPathComponent($0).absoluteString == requestUrl.absoluteString }),
           let jsonName = testJSONDictionary[key],
           let jsonPath = jsonPaths.first(where: { $0.hasSuffix(jsonName + ".json") || $0.hasSuffix(jsonName + ".JSON") }),
           let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
            
            data = jsonData
            urlResponse = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (data, urlResponse)
        }
        
        do {
            (data, urlResponse) = try await session.data(for: request)
            session.finishTasksAndInvalidate()
        } catch {
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
        var result: Data?
        if let data = data as? Data {
            result = data
        } else if let model = data as? any Encodable,
                  let data = mapToArray(dictionary: model.toDictionary()).joinedWithAmpersands().data(using: .utf8) {
            result = data
        } else if let dict = data as? [String: Any],
                  let data = mapToArray(dictionary: dict).joinedWithAmpersands().data(using: .utf8) {
            result = data
        }
        
        return result
    }
    
    func prepareBody(data: Any) -> Data? {
        var result: Data?
        if let data = data as? Data {
            result = data
        } else if let model = data as? any Encodable,
                  let data = try? model.toJsonData() {
            result = data
        } else if let dict = data as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            result = data
        }
        
        return result
    }
}

private extension Snowdrop.Core {
    func mapToArray(dictionary: [String: Any]) -> [String] {
        dictionary.reduce([]) {
            guard let value = valueOrNil($1.value) else { return $0 }
            return $0 + ["\($1.key)=\(value)"]
        }
    }
}

fileprivate extension Collection where Element == String {
    func joinedWithAmpersands() -> String {
        self.joined(separator: "&")
    }
}
