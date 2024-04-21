//
//  SnowdropCore.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 11/02/2024.
//

import Foundation

public extension Snowdrop {
    class Core {
        private static var didRetry: [String] = []
        
        public static func prepareUrlEncodedBody(data: Any) -> Data? {
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
        
        public static func prepareBody(data: Any) -> Data? {
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
        
        @discardableResult
        public static func performRequest(
            session: URLSession,
            request: URLRequest,
            onResponse: ((Data?, HTTPURLResponse) -> Data?)?
        ) async throws -> (Data?, HTTPURLResponse) {
            var data: Data?
            var urlResponse: URLResponse?
            
            do {
                (data, urlResponse) = try await session.data(for: request)
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
            
            guard let response = urlResponse as? HTTPURLResponse else {
                throw SnowdropError(type: .failedToMapResponse)
            }
            
            return (data, response)
        }
        
        public static func performRequestAndDecode<T: Codable>(
            session: URLSession,
            request: URLRequest,
            onResponse: ((Data?, HTTPURLResponse) -> Data?)?
        ) async throws -> T {
            let (data, response) = try await performRequest(session: session, request: request, onResponse: onResponse)
            let finalData = onResponse?(data, response) ?? data
            
            if let castedData = finalData as? T {
                return castedData
            }
            
            guard let unwrappedData = finalData,
                    let decodedData = try? Snowdrop.Config.defaultJSONDecoder.decode(T.self, from: unwrappedData) else {
                throw SnowdropError(
                    type: .failedToMapResponse,
                    details: .init(
                        statusCode: response.statusCode,
                        localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                        url: response.url,
                        mimeType: response.mimeType,
                        headers: response.allHeaderFields),
                    data: finalData
                )
            }
            
            return decodedData
        }
        
        private static func mapToArray(dictionary: [String: Any]) -> [String] {
            dictionary.reduce([]) {
                guard let value = valueOrNil($1.value) else { return $0 }
                return $0 + ["\($1.key)=\(value)"]
            }
        }
    }
}

fileprivate extension Collection where Element == String {
    func joinedWithAmpersands() -> String {
        self.joined(separator: "&")
    }
}
