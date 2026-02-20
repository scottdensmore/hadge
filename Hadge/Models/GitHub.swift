import UIKit
import KeychainAccess
import OctoKit
import SwiftyJSON
import AuthenticationServices
import os.log

extension Notification.Name {
    static let didSignIn = Notification.Name("didSignIn")
    static let signInFailed = Notification.Name("signInFailed")
    static let didSignOut = Notification.Name("didSignOut")
    static let didSetUpRepository = Notification.Name("didSetUpRepository")
}

protocol GitHubCredentialStore {
    subscript(_ key: String) -> String? { get set }
}

extension Keychain: GitHubCredentialStore {}

enum GitHubResponseError: Error {
    case nonHTTPResponse
    case invalidData
}

class GitHub {
    static let sharedInstance = GitHub()

    #if targetEnvironment(simulator)
        static let defaultRepository = "health.debug"
    #else
        static let defaultRepository = "health"
    #endif

    var configURL: URL?
    var config: TokenConfiguration?
    var oauth: OAuthConfiguration?
    var keychain: GitHubCredentialStore?
    var lastEventId: Int? = 0
    var requestExecutor: ((URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> Void)?
    private var authenticationSession: ASWebAuthenticationSession?

    static func shared() -> GitHub {
        return sharedInstance
    }

    func prepare() {
        if keychain == nil {
            keychain = Keychain(service: AppIdentifiers.keychainService)
        }

        if accessToken() == nil {
            oauth = OAuthConfiguration(token: Secrets.gitHubClientId, secret: Secrets.gitHubClientSecret, scopes: ["repo"])
            configURL = oauth!.authenticate()
        } else {
            config = TokenConfiguration(accessToken())
        }
    }

    func isSignedIn() -> Bool {
        guard let token = accessToken(), !token.isEmpty,
              let user = username(), !user.isEmpty else {
            return false
        }
        return true
    }

    func returnAuthenticatedUsername() -> String {
        return username() ?? "github"
    }

    func signIn(_ contextProvider: ASWebAuthenticationPresentationContextProviding?) {
        guard let configURL else {
            NotificationCenter.default.post(name: .signInFailed, object: nil)
            return
        }

        authenticationSession = ASWebAuthenticationSession(url: configURL, callbackURLScheme: "hadge") { url, error in
            defer { self.authenticationSession = nil }

            guard error == nil, let url = url else {
                NotificationCenter.default.post(name: .signInFailed, object: nil)
                return
            }

            GitHub.shared().process(url: url) { username in
                if username != nil {
                    NotificationCenter.default.post(name: .didSignIn, object: nil)
                } else {
                    NotificationCenter.default.post(name: .signInFailed, object: nil)
                }
            }
        }
        authenticationSession?.prefersEphemeralWebBrowserSession = true
        authenticationSession?.presentationContextProvider = contextProvider
        authenticationSession?.start()
    }

    func signOut() {
        self.keychain?["username"] = nil
        self.keychain?["token"] = nil
        self.prepare()
    }

    func process(url: URL, completionHandler: @escaping (String?) -> Void) {
        guard let oauth else {
            completionHandler(nil)
            return
        }

        oauth.handleOpenURL(url: url) { config in
            self.loadCurrentUser(config: config) { username in
                completionHandler(username)
            }
        }
    }

    func storeToken(token: String) {
        self.loadCurrentUser(config: TokenConfiguration(token)) { _ in }
    }

    func accessToken() -> String? {
        guard let token = self.keychain?["token"], !token.isEmpty else { return nil }
        return token
    }

    func username() -> String? {
        guard let username = self.keychain?["username"], !username.isEmpty else { return nil }
        return username
    }

    func fullname() -> String? {
        self.keychain?["fullname"]
    }

    func loadCurrentUser(config: TokenConfiguration, completionHandler: @escaping (String?) -> Void) {
        _ = Octokit(config).me { response in
            switch response {
            case .success(let user):
                os_log("GitHub User: %@", type: .debug, user.login!)

                self.keychain?["fullname"] = user.name
                self.keychain?["username"] = user.login
                self.keychain?["token"] = config.accessToken
                os_log("Token stored", type: .debug)

                self.config = TokenConfiguration(self.accessToken())
                completionHandler(user.login)
            case .failure(let error):
                os_log("Error while loading user: %@", type: .debug, error.localizedDescription)
                completionHandler(nil)
            }
        }
    }

    func refreshCurrentUser() {
        guard let config else { return }
        _ = Octokit(config).me { response in
            switch response {
            case .success(let user):
                self.keychain?["fullname"] = user.name
                self.keychain?["username"] = user.login
            case .failure(let error as NSError):
                if error.code == 401 {
                    self.signOut()
                    NotificationCenter.default.post(name: .didSignOut, object: nil)
                }
                os_log("Error while loading user: %@", type: .debug, error.localizedDescription)
            }
        }
    }

}

extension GitHub {
    func getRepository(completionHandler: @escaping (String?) -> Void) {
        guard let config,
              let currentUsername = self.username() else {
            completionHandler(nil)
            return
        }

        Octokit(config).repository(owner: currentUsername, name: GitHub.defaultRepository) { response in
            switch response {
            case .success(let repository):
                os_log("Repository ID: %d", type: .debug, repository.id)
                completionHandler("\(repository.id)")
            case .failure:
                self.createRepository(completionHandler: completionHandler)
            }
        }
    }

    func createRepository(completionHandler: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.github.com/user/repos")!
        guard var request = self.createRequest(url: url, httpMethod: "POST") else {
            completionHandler(nil)
            return
        }
        let parameters: [String: Any] = [
            "name": GitHub.defaultRepository,
            "private": true,
            "auto_init": true
        ]
        do {
            request.httpBody = try JSON(parameters).rawData()

            self.handleRequest(request, completionHandler: { json, _, _ in
                completionHandler(json?["id"].stringValue)
            })
        } catch {
            completionHandler(nil)
        }
    }

    func getFile(path: String, completionHandler: @escaping (String?) -> Void) {
        guard let currentUsername = self.username() else {
            completionHandler(nil)
            return
        }

        let escapedPath = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = URL(string: "https://api.github.com/repos/\(currentUsername)/\(GitHub.defaultRepository)/contents/\(escapedPath)")!
        guard let request = self.createRequest(url: url, httpMethod: "GET") else {
            completionHandler(nil)
            return
        }

        self.handleRequest(request, completionHandler: { json, _, _ in
            let sha = json?["sha"].string
            if let sha {
                os_log("File sha: %@", type: .debug, sha)
            }
            completionHandler(sha)
        })
    }

    func updateFile(path: String, content: String, message: String, completionHandler: @escaping (String?) -> Void) {
        guard let contentData = content.data(using: .utf8),
              let username = self.username() else {
            completionHandler(nil)
            return
        }

        getFile(path: path) { sha in
            let escapedPath = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let url = URL(string: "https://api.github.com/repos/\(username)/\(GitHub.defaultRepository)/contents/\(escapedPath)")!
            guard var request = self.createRequest(url: url, httpMethod: "PUT") else {
                completionHandler(nil)
                return
            }
            let parameters: [String: Any] = [
                "message": message,
                "content": contentData.base64EncodedString(),
                "author": [
                    "name": "Hadge",
                    "email": "hadge@entire.io"
                ]
            ]
            var mutableParameters = parameters
            if let sha, !sha.isEmpty {
                mutableParameters["sha"] = sha
            }
            do {
                request.httpBody = try JSON(mutableParameters).rawData()

                self.handleRequest(request, completionHandler: { json, _, _ in
                    let sha = json?["content"]["sha"].string
                    if sha != nil {
                        os_log("File updated: %@", type: .debug, sha!)
                    }
                    completionHandler(sha)
                })
            } catch {
                completionHandler(nil)
            }
        }
    }
}

extension GitHub {
    func createRequest(url: URL, httpMethod: String) -> URLRequest? {
        guard let username = username(), let token = accessToken() else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let loginData = String(format: "%@:%@", username, token).data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")

        return request
    }

    func handleRequest(_ request: URLRequest, completionHandler: @escaping (JSON?, Int, Error?) -> Void) {
        let execute = requestExecutor ?? { request, callback in
            let configuration = URLSessionConfiguration.ephemeral
            let session: Foundation.URLSession = Foundation.URLSession(configuration: configuration)
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { data, response, error in
                callback(data, response, error)
            })
            task.resume()
        }

        execute(request) { data, response, error in
            if let error {
                completionHandler(nil, 0, error)
                return
            }

            guard let httpStatus = response as? HTTPURLResponse else {
                completionHandler(nil, 0, GitHubResponseError.nonHTTPResponse)
                return
            }

            guard let data else {
                completionHandler(nil, httpStatus.statusCode, GitHubResponseError.invalidData)
                return
            }

            do {
                let json = try JSON(data: data)
                completionHandler(json, httpStatus.statusCode, nil)
            } catch {
                completionHandler(nil, httpStatus.statusCode, error)
            }
        }
    }
}
