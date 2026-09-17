//
//  WebAuthPresenter.swift
//  DiscoScan
//

import AuthenticationServices
import UIKit

enum DiscogsOAuthError: Error, LocalizedError {
    case authorizationCancelled
    case missingVerifier
    case sessionStartFailed
    case missingPresentationAnchor

    var errorDescription: String? {
        switch self {
        case .authorizationCancelled:
            return "Discogs authorization was cancelled."
        case .missingVerifier:
            return "Discogs did not return an OAuth verifier."
        case .sessionStartFailed:
            return "Unable to start the Discogs authorization session."
        case .missingPresentationAnchor:
            return "Unable to find a window to present Discogs authorization."
        }
    }
}

@MainActor
final class WebAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var activeSession: ASWebAuthenticationSession?

    func authorize(url: URL, callbackScheme: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                defer { self?.activeSession = nil }

                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: DiscogsOAuthError.authorizationCancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard
                    let callbackURL,
                    let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                    let verifier = components.queryItems?.first(where: { $0.name == "oauth_verifier" })?.value
                else {
                    continuation.resume(throwing: DiscogsOAuthError.missingVerifier)
                    return
                }

                continuation.resume(returning: verifier)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            activeSession = session

            guard session.start() else {
                activeSession = nil
                continuation.resume(throwing: DiscogsOAuthError.sessionStartFailed)
                return
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        let foregroundScene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first

        guard let scene = foregroundScene else {
            preconditionFailure("No UIWindowScene available for OAuth presentation")
        }

        if let keyWindow = scene.keyWindow {
            return keyWindow
        }

        if let window = scene.windows.first {
            return window
        }

        return ASPresentationAnchor(windowScene: scene)
    }
}
