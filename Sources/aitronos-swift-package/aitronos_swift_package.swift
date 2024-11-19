public class Aitronos: @unchecked Sendable {
    public var appHive: AppHive {
        AppHive(userToken: userToken)
    }
    
    public var freddyApi: FreddyApi {
        FreddyApi(userToken: userToken)
    }
    
    public var assistantMessaging: FreddyApi.AssistantMessaging {
        FreddyApi.AssistantMessaging(userToken: userToken)
    }
    
    public private(set) var userToken = ""

    public init(apiKey: String) {
        self.userToken = apiKey
    }

    @available(macOS 10.15, *)
    public init(usernmeEmail: String, password: String) async throws {
        do {
            let loginResponse = try await AppHive.login(usernmeEmail: usernmeEmail, password: password)
            self.userToken = loginResponse.token
        } catch {
            throw error
        }
    }
}
