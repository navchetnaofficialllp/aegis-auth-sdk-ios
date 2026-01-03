import XCTest
@testable import AegisAuth

final class AegisAuthTests: XCTestCase {
    
    var aegisAuth: AegisAuth!
    
    override func setUpWithError() throws {
        aegisAuth = AegisAuth(apiKey: "test_api_key")
    }
    
    override func tearDownWithError() throws {
        aegisAuth = nil
    }
    
    func testInitialization() throws {
        XCTAssertNotNil(aegisAuth)
        XCTAssertFalse(aegisAuth.isAuthenticated())
    }
    
    func testAuthenticationStatus() throws {
        // Initially not authenticated
        XCTAssertFalse(aegisAuth.isAuthenticated())
    }
}