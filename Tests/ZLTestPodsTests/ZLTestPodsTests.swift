import XCTest
@testable import ZLTestPods

final class ZLTestPodsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ZLTestPods().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
