//
//  Netty.swift
//  Netty
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

public class Netty {
    
}

public extension Netty {
    class Config {
        public static var pinningModes: PinningMode = PinningMode(rawValue: 0)
        public static var urlsExcludedFromPinning: [String] = []
        public static var defaultJSONDecoder: JSONDecoder = .init()
        public static var accessTokenStorage: AccessTokenStorage = DefaultStorage()
        public static var accessTokenErrorCodes: [Int] = [401]
        
        public static func getSession(ignorePinning: Bool = false) -> URLSession {
            let operationQueue = OperationQueue()
            operationQueue.qualityOfService = .utility
            
            if pinningModes.rawValue == 0 || ignorePinning {
                return URLSession(configuration: .default,
                                  delegate: nil,
                                  delegateQueue: operationQueue)
            }
            
            let delegate = SessionDelegate(mode: pinningModes, excludedURLs: urlsExcludedFromPinning)
            return URLSession(configuration: .default, delegate: delegate, delegateQueue: operationQueue)
        }
    }
}

public extension Netty {
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
        
        public static func dataWithBoundary(_ file: Encodable, payloadDescription: PayloadDescription) -> Data {
            var data = Data()
            let contentDisposition = "Content-Disposition: form-data; name=\"\(payloadDescription.name)\"; filename=\"\(payloadDescription.fileName)\"\r\n"
            
            guard let nameData = "--\(payloadDescription.name)\r\n".data(using: .utf8),
                  let closingData = "\r\n--\(payloadDescription.name)--\r\n".data(using: .utf8),
                  let contentDispData = contentDisposition.data(using: .utf8),
                  let contentTypeData = "Content-Type: \(payloadDescription.mimeType)\r\n\r\n".data(using: .utf8),
                  let fileData = try? file.toJsonData() else {
                return data
            }
            
            data.append(nameData)
            data.append(contentDispData)
            data.append(contentTypeData)
            data.append(fileData)
            data.append(closingData)
            
            return data
        }
        
        public static func sendRequest<T: Codable>(
            session: URLSession,
            request: URLRequest,
            requiresAccessToken: Bool,
            tokenLabel: String?,
            onResponse: ((Data?, HTTPURLResponse) -> Data?)?
        ) async throws -> T {
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
                let errorType: NettyError.ErrorType = networkErrorCodes.contains(error.code) ? .noInternetConnection : .unexpectedResponse
                let errorDetails = NettyErrorDetails(statusCode: error.code,
                                                     localizedString: error.localizedDescription)
                let nettyError = NettyError(type: errorType, details: errorDetails)
                throw nettyError
            }
            
            
            
            guard let response = urlResponse as? HTTPURLResponse else {
                throw NettyError(type: .failedToMapResponse)
            }
            
            let finalData = onResponse?(data, response) ?? data
            
            guard [200, 201, 204].contains(response.statusCode) else {
                throw NettyError(
                    type: .unexpectedResponse,
                    details: .init(
                        statusCode: response.statusCode,
                        localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                        url: response.url,
                        mimeType: response.mimeType,
                        headers: response.allHeaderFields),
                    data: finalData
                )
            }
            
            if Netty.Config.accessTokenErrorCodes.contains(response.statusCode) && requiresAccessToken, let tokenLabel {
                let convertibleToken: AccessTokenConvertible? = try await (self as? Recoverable)?.retryAuthentication()
                
                let identifier = request.url!.absoluteString
                
                if !didRetry.contains(identifier), let token = convertibleToken?.convert() {
                    didRetry.append(identifier)
                    Netty.Config.accessTokenStorage.store(token, for: tokenLabel)
                    
                    return try await sendRequest(session: session,
                                                 request: request,
                                                 requiresAccessToken: requiresAccessToken,
                                                 tokenLabel: tokenLabel,
                                                 onResponse: onResponse)
                } else {
                    throw NettyError(
                        type: .authenticationFailed,
                        details: .init(
                            statusCode: response.statusCode,
                            localizedString: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                            url: response.url,
                            mimeType: response.mimeType,
                            headers: response.allHeaderFields),
                        data: nil
                    )
                }
            }
            
            if let castedData = finalData as? T {
                return castedData
            }
            
            guard let unwrappedData = finalData,
                    let decodedData = try? Netty.Config.defaultJSONDecoder.decode(T.self, from: unwrappedData) else {
                throw NettyError(type: .failedToMapResponse)
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
