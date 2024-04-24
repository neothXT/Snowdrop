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
                rawUrl: String,
                requestBlocks: [String: RequestHandler],
                responseBlocks: [String: ResponseHandler]
            ) async throws -> (Data?, HTTPURLResponse) {
                let session = Snowdrop.config.getSession()
                var data: Data?
                var urlResponse: URLResponse?
                
                var finalRequest = request
                applyRequestBlocks(requestBlocks, for: &finalRequest, rawUrl: rawUrl)
    
                do {
                    (data, urlResponse) = try await session.data(for: finalRequest)
                } catch {
                    let networkErrorCodes = [
                        NSURLErrorNetworkConnectionLost,
                        NSURLErrorNotConnectedToInternet,
                        NSURLErrorCannotLoadFromNetwork
                    ]
                    let error = error as NSError
                    let errorType: SnowdropError.ErrorType = networkErrorCodes.contains(error.code) ? .noInternetConnection : .unexpectedResponse
                    let errorDetails = SnowdropErrorDetails(statusCode: error.code,
                                                            localizedString: error.localizedDescription)
                    let SnowdropError = SnowdropError(type: errorType, details: errorDetails)
                    throw SnowdropError
                }
    
                guard var response = urlResponse as? HTTPURLResponse else {
                    throw SnowdropError(type: .failedToMapResponse)
                }
                
                guard var finalData = data else {
                    return (data, response)
                }
                
                applyResponseBlocks(responseBlocks, forData: &finalData, response: &response, rawUrl: rawUrl)
    
                return (finalData, response)
            }
    
            func performRequestAndDecode<T: Codable>(
                _ request: URLRequest,
                rawUrl: String,
                requestBlocks: [String: RequestHandler],
                responseBlocks: [String: ResponseHandler]
            ) async throws -> T {
                let (data, response) = try await performRequest(
                    request,
                    rawUrl: rawUrl,
                    requestBlocks: requestBlocks,
                    responseBlocks: responseBlocks
                )
    
                guard let unwrappedData = data,
                        let decodedData = try? Snowdrop.config.defaultJSONDecoder.decode(T.self, from: unwrappedData) else {
                    throw SnowdropError(
                        type: .failedToMapResponse,
                        details: .init(
                            statusCode: response.statusCode,
                            localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                            url: response.url,
                            mimeType: response.mimeType,
                            headers: response.allHeaderFields),
                        data: data
                    )
                }
    
                return decodedData
            }
}

// MARK: RequestBlock appliance

extension Snowdrop.Core {
    private func applyRequestBlocks(
        _ blocks: [String: RequestHandler],
        for request: inout URLRequest,
        rawUrl: String
    ) {
        let pathBlocks = blocks.filter { $0.key == rawUrl || $0.key == "all" }.values
        
        pathBlocks.forEach { block in
            request = block(request)
        }
    }
    
    private func applyResponseBlocks(
        _ blocks: [String: ResponseHandler],
        forData data: inout Data,
        response: inout HTTPURLResponse,
        rawUrl: String
    ) {
        let pathBlocks = blocks.filter { $0.key == rawUrl || $0.key == "all" }.values
        
        pathBlocks.forEach { block in
            (data, response) = block(data, response)
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
