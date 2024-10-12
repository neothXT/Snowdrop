//
//  CertificateExplorer.swift
//  Snowdrop
//
//  Created by Maciej Burdzicki on 29/01/2024.
//

import Foundation

struct CertificateExplorer {
	func fetchCertificates() -> [SecCertificate] {
		var certificates: [SecCertificate] = []
		
		fetchCertificatePaths().forEach {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: $0)) as CFData,
				let cert = SecCertificateCreateWithData(nil, data) {
				certificates.append(cert)
			}
		}
		
		return certificates
	}
	
	func fetchSLLKeys() -> [SecKey] {
		var keys: [SecKey] = []
		fetchCertificatePaths().forEach {
			if let certificateData = try? Data(contentsOf: URL(fileURLWithPath: $0)) as CFData,
			   let certificate = SecCertificateCreateWithData(nil, certificateData),
			   let key = publicKey(for: certificate) {
				keys.append(key)
			}
		}
		
		return keys
	}
	
	func publicKey(for certificate: SecCertificate) -> SecKey? {
		var trust: SecTrust?
		let trustStatus = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
		
		guard let trust = trust, trustStatus == errSecSuccess else { return nil }
		
		return SecTrustCopyKey(trust)
	}
	
	private func fetchCertificatePaths() -> [String] {
		Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]).reduce([]) {
			$0 + Bundle.main.paths(forResourcesOfType: $1, inDirectory: nil)
		}
	}
}
