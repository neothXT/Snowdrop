//
//  WebSocket.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 04/02/2024.
//

import Foundation
import Combine

open class WebSocket: NSObject {
    private var webSocket: URLSessionWebSocketTask
    
    private(set) public var failedToConnect: Bool = false
    private(set) public var isConnecting: Bool = false
    private(set) public var isConnected: Bool = false
    
    public var onConnectionEstablished: (() -> Void)?
    public var onConnectionClosed: (() -> Void)?
    
    private var connectionParameters: WebSocketConnectionParameters?
    
    public init(socket: URLSessionWebSocketTask, ignorePinning: Bool = false) {
        webSocket = socket
        super.init()

        if #available(iOS 15.0, macOS 12.0, *) {
            webSocket.delegate = self
        } else {
            #if DEBUG
            print("Cannot assign delegate. Feature available only in iOS 15.0 or newer")
            #endif
        }
    }
    
    public convenience init(url: URL, protocols: [String] = [], ignorePinning: Bool = false) {
        let session = Snowdrop.Config.getSession(ignorePinning: ignorePinning)
        let webSocket = protocols.count > 0 ? session.webSocketTask(with: url, protocols: protocols) : session.webSocketTask(with: url)
        self.init(socket: webSocket, ignorePinning: ignorePinning)
        self.connectionParameters = WebSocketConnectionParameters(url: url, protocols: protocols,
                                                                  ignorePinning: ignorePinning)
    }
    
    public convenience init(request: URLRequest, ignorePinning: Bool = false) {
        let session = Snowdrop.Config.getSession(ignorePinning: ignorePinning)
        let webSocket = session.webSocketTask(with: request)
        self.init(socket: webSocket, ignorePinning: ignorePinning)
        self.connectionParameters = WebSocketConnectionParameters(request: request, ignorePinning: ignorePinning)
    }
    
    public convenience init?(connectionParameters: WebSocketConnectionParameters) {
        if let request = connectionParameters.request {
            self.init(request: request, ignorePinning: connectionParameters.ignorePinning)
        } else if let url = connectionParameters.url {
            self.init(url: url, protocols: connectionParameters.protocols,
                      ignorePinning: connectionParameters.ignorePinning)
        } else {
            return nil
        }
    }
    
    /// Establishes connection with WebSocket server
    public func connect() {
        webSocket.resume()
        isConnecting = true
        
        if #unavailable(iOS 15.0, macOS 12.0) {
            ping { [weak self] in
                self?.isConnecting = false
                self?.isConnected = true
                self?.onConnectionEstablished?()
            } onError: { [weak self] _ in
                self?.isConnecting = false
                self?.isConnected = false
            }
        }
    }
    
    /// Reestablishes WebSocket connection. If the instance was initially created directly with a socket object, it is required to provide new socket object.
    @discardableResult
    public func reconnect(withSocket socket: URLSessionWebSocketTask? = nil) -> Bool {
        guard let params = connectionParameters else { return false }
        
        var nullableSocket = socket
        let session = Snowdrop.Config.getSession(ignorePinning: params.ignorePinning)
        
        if let url = params.url {
            nullableSocket = params.protocols.count > 0 ? session.webSocketTask(with: url, protocols: params.protocols) : session.webSocketTask(with: url)
        } else if let request = params.request {
            nullableSocket = session.webSocketTask(with: request)
        }
        
        guard let finalSocket = nullableSocket else { return false }
        
        webSocket = finalSocket
        
        if #available(iOS 15.0, macOS 12.0, *) {
            webSocket.delegate = self
        } else {
            #if DEBUG
            print("Cannot assign delegate. Feature available only in iOS 15.0 or newer")
            #endif
        }
        
        connect()
        return true
    }
    
    /// Reestablishes WebSocket connection and starts to listen immediately
    @discardableResult
    public func reconnectAndListen(withSocket socket: URLSessionWebSocketTask? = nil,
                                   onReceive: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) -> Bool {
        guard reconnect(withSocket: socket) else { return false }
        listen(onReceive: onReceive)
        return true
    }
    
    /// Updates WebSocket connection status reconnects if requested
    public func updateConnectionStatus(onFail: @escaping () -> Void) {
        ping { [weak self] in
            self?.isConnected = true
        } onError: { _ in
            onFail()
        }
    }
    
    /// Closes connection with WebSocket server
    public func disconnect() {
        isConnecting = false
        isConnected = false
        webSocket.cancel(with: .goingAway, reason: nil)
        onConnectionClosed?()
    }
    
    /// Sends message to WebSocket server
    open func send(_ message: URLSessionWebSocketTask.Message, completion: @escaping (Error?) -> Void) {
        if !isConnected {
            if isConnecting {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.send(message, completion: completion)
                }
                return
            }
            
            #if DEBUG
            print("Connect to WebSocket before subscribing for messages!")
            #endif
            completion(SnowdropError(type: .notConnected))
            return
        }
        
        webSocket.send(message, completionHandler: completion)
    }
    
    open func listen(onReceive: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        if !isConnected {
            if isConnecting {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.listen(onReceive: onReceive)
                }
                return
            }
            
            #if DEBUG
            print("Connect to WebSocket before subscribing for messages!")
            #endif
            onReceive(.failure(SnowdropError(type: .notConnected)))
            return
        }
        
        webSocket.receive { [weak self] in
            onReceive($0)
            self?.listen(onReceive: onReceive)
        }
    }
    
    open func ping(withTimeInterval interval: DispatchTime? = nil, onSuccess: (() -> Void)? = nil, onError: @escaping (Error) -> Void, stopAfterError: Bool = true) {
        webSocket.sendPing { [weak self] in
            if let error = $0 {
                onError(error)
                if stopAfterError {
                    return
                }
            }
            
            if let interval = interval {
                DispatchQueue.main.asyncAfter(deadline: interval) { [weak self] in
                    self?.ping(withTimeInterval: interval, onError: onError)
                }
            }
        }
    }
}

extension WebSocket: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnecting = false
        isConnected = true
        onConnectionEstablished?()
    }

    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnecting = false
        isConnected = false
        onConnectionClosed?()
    }
}
