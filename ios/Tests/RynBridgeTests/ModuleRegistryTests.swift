import XCTest
@testable import RynBridge

final class ModuleRegistryTests: XCTestCase {
    func testRegisterAndGetAction() throws {
        let registry = ModuleRegistry()
        let module = TestModule(name: "test", version: "0.1.0", actions: [
            "doSomething": { _ in return ["result": .string("done")] }
        ])
        registry.register(module)

        let handler = try registry.getAction(module: "test", action: "doSomething")
        XCTAssertNotNil(handler)
    }

    func testModuleNotFound() {
        let registry = ModuleRegistry()
        XCTAssertThrowsError(try registry.getAction(module: "missing", action: "doSomething")) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .moduleNotFound)
        }
    }

    func testActionNotFound() {
        let registry = ModuleRegistry()
        let module = TestModule(name: "test", version: "0.1.0", actions: [:])
        registry.register(module)

        XCTAssertThrowsError(try registry.getAction(module: "test", action: "missing")) { error in
            let bridgeError = error as! RynBridgeError
            XCTAssertEqual(bridgeError.code, .actionNotFound)
        }
    }

    func testHasModule() {
        let registry = ModuleRegistry()
        let module = TestModule(name: "test", version: "0.1.0", actions: [:])
        XCTAssertFalse(registry.hasModule("test"))
        registry.register(module)
        XCTAssertTrue(registry.hasModule("test"))
    }

    func testRegisterOverwritesExisting() throws {
        let registry = ModuleRegistry()
        let module1 = TestModule(name: "test", version: "0.1.0", actions: [
            "action1": { _ in return [:] }
        ])
        let module2 = TestModule(name: "test", version: "0.2.0", actions: [
            "action2": { _ in return [:] }
        ])

        registry.register(module1)
        registry.register(module2)

        XCTAssertThrowsError(try registry.getAction(module: "test", action: "action1"))
        _ = try registry.getAction(module: "test", action: "action2")
    }
}

private struct TestModule: BridgeModule {
    let name: String
    let version: String
    let actions: [String: ActionHandler]
}
