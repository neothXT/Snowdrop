//
//  SessionDelegate.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation
import Combine

public class SessionDelegate: NSObject, URLSessionDelegate {
	private let certExplorer = CertificateExplorer()
    private let mode: PinningMode?
	private let excludedURLs: [String]
	
	private lazy var pinnedCerts = certExplorer.fetchCertificates()
	private lazy var pinnedKeys = certExplorer.fetchSLLKeys()
    
    public init(mode: PinningMode?, excludedURLs: [String]) {
        self.excludedURLs = excludedURLs
        self.mode = mode
    }
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		
		var result = true
		
		// Check if server got any security certificates
		guard let trust = challenge.protectionSpace.serverTrust, SecTrustGetCertificateCount(trust) > 0 else {
			completionHandler(.cancelAuthenticationChallenge, nil)
			return
		}
		
		let challengeCompletion: (ChallengeResult, Bool) -> Void = { challengeResult, execute in
			result = challengeResult != .failure
			
			if !execute { return }
			
			switch challengeResult {
			case .success:
				completionHandler(.useCredential, URLCredential(trust: trust))
				
			case .ignored:
				completionHandler(.performDefaultHandling, nil)
				
			case .failure:
				completionHandler(.cancelAuthenticationChallenge, nil)
			}
		}
		
		if let baseURL = task.originalRequest?.url?.baseURL?.absoluteString, excludedURLs.contains(baseURL) {
			challengeCompletion(.ignored, true)
			return
		}
		
		challengeCertificateIfNeeded(trust: trust, completionHandler: challengeCompletion)
		
		if !result { return }
		
		challengeKeyIfNeeded(trust: trust, completionHandler: challengeCompletion)
	}
	
	private func challengeCertificateIfNeeded(trust: SecTrust, completionHandler: @escaping (ChallengeResult, Bool) -> Void) {
        guard let mode, mode.contains(.certificate) else {
            completionHandler(.ignored, false)
            return
        }
        
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0) else {
			completionHandler(.failure, true)
			return
		}
		
		completionHandler(pinnedCerts.contains(serverCert) ? .success: .failure, !pinnedCerts.contains(serverCert))
	}
	
	private func challengeKeyIfNeeded(trust: SecTrust, completionHandler: @escaping (ChallengeResult, Bool) -> Void) {
        guard let mode, mode.contains(.ssl) else {
            completionHandler(.ignored, false)
            return
        }
        
		guard let serverCert = SecTrustGetCertificateAtIndex(trust, 0),
			  let key = certExplorer.publicKey(for: serverCert) else {
			completionHandler(.failure, true)
			return
		}
		
		completionHandler(pinnedKeys.contains(key) ? .success: .failure, true)
	}
}

extension SessionDelegate {
	enum ChallengeResult {
		case success, failure, ignored
	}
}
