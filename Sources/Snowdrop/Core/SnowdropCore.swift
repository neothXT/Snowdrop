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
        pinning: PinningMode?,
        urlsExcludedFromPinning: [String],
        requestBlocks: [String: RequestHandler],
        responseBlocks: [String: ResponseHandler]
    ) async throws -> (Data?, HTTPURLResponse) {
        let session = getSession(pinningMode: pinning, urlsExcludedFromPinning: urlsExcludedFromPinning)
        var data: Data?
        var urlResponse: URLResponse?
        
        var finalRequest = request
        applyRequestBlocks(requestBlocks, for: &finalRequest)
        
        do {
            (data, urlResponse) = try await session.data(for: finalRequest)
            session.finishTasksAndInvalidate()
        } catch {
            try handleError(error as NSError)
        }
        
        guard var response = urlResponse as? HTTPURLResponse else {
            throw SnowdropError(type: .failedToMapResponse)
        }
        
        guard var finalData = data else {
            return (data, response)
        }
        
        applyResponseBlocks(responseBlocks, forData: &finalData, response: &response)
        
        return (finalData, response)
    }
    
    func performRequestAndDecode<T: Codable>(
        _ request: URLRequest,
        decoder: JSONDecoder,
        pinning: PinningMode?,
        urlsExcludedFromPinning: [String],
        requestBlocks: [String: RequestHandler],
        responseBlocks: [String: ResponseHandler]
    ) async throws -> T {
        let (data, _) = try await performRequest(
            request,
            pinning: pinning,
            urlsExcludedFromPinning: urlsExcludedFromPinning,
            requestBlocks: requestBlocks,
            responseBlocks: responseBlocks
        )
        
        guard let unwrappedData = data else {
            throw SnowdropError(type: .unexpectedResponse)
        }
        
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
    
    private func getSession(pinningMode: PinningMode?, urlsExcludedFromPinning: [String]) -> URLSession {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .utility
        let delegate = SessionDelegate(mode: pinningMode, excludedURLs: urlsExcludedFromPinning)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
    }
    
    private func handleError(_ error: NSError) throws {
        let networkErrorCodes = [
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorCannotLoadFromNetwork
        ]
        
        let errorType: SnowdropError.ErrorType = networkErrorCodes.contains(error.code) ? .noInternetConnection : .unexpectedResponse
        let errorDetails = SnowdropErrorDetails(statusCode: error.code,
                                                localizedString: error.localizedDescription)
        let SnowdropError = SnowdropError(type: errorType, details: errorDetails)
        throw SnowdropError
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
