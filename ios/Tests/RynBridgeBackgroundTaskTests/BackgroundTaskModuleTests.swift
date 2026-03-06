import XCTest
@testable import RynBridge
@testable import RynBridgeBackgroundTask

final class BackgroundTaskModuleTests: XCTestCase {
    func testScheduleTask() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["scheduleTask"]!

        let result = try await handler([
            "taskId": .string("sync-data"),
            "type": .string("processing"),
            "interval": .int(3600),
            "delay": .int(60),
            "requiresNetwork": .bool(true),
            "requiresCharging": .bool(false),
        ])
        XCTAssertEqual(result["taskId"]?.stringValue, "sync-data")
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastScheduledTaskId, "sync-data")
        XCTAssertEqual(provider.lastScheduledType, "processing")
        XCTAssertEqual(provider.lastScheduledInterval, 3600)
        XCTAssertEqual(provider.lastScheduledDelay, 60)
        XCTAssertEqual(provider.lastScheduledRequiresNetwork, true)
        XCTAssertEqual(provider.lastScheduledRequiresCharging, false)
    }

    func testScheduleTaskWithDefaults() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["scheduleTask"]!

        let result = try await handler([
            "taskId": .string("cleanup"),
            "type": .string("maintenance"),
        ])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertNil(provider.lastScheduledInterval)
        XCTAssertNil(provider.lastScheduledDelay)
        XCTAssertEqual(provider.lastScheduledRequiresNetwork, false)
        XCTAssertEqual(provider.lastScheduledRequiresCharging, false)
    }

    func testScheduleTaskMissingTaskId() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["scheduleTask"]!

        do {
            _ = try await handler(["type": .string("processing")])
            XCTFail("Expected error for missing taskId")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testScheduleTaskMissingType() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["scheduleTask"]!

        do {
            _ = try await handler(["taskId": .string("sync-data")])
            XCTFail("Expected error for missing type")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testCancelTask() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["cancelTask"]!

        let result = try await handler(["taskId": .string("sync-data")])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertEqual(provider.lastCancelledTaskId, "sync-data")
    }

    func testCancelTaskMissingTaskId() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["cancelTask"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error for missing taskId")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testCancelAllTasks() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["cancelAllTasks"]!

        let result = try await handler([:])
        XCTAssertEqual(result["success"]?.boolValue, true)
        XCTAssertTrue(provider.cancelAllTasksCalled)
    }

    func testGetScheduledTasks() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["getScheduledTasks"]!

        let result = try await handler([:])
        let tasks = result["tasks"]?.arrayValue
        XCTAssertNotNil(tasks)
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.dictionaryValue?["taskId"]?.stringValue, "sync-data")
        XCTAssertEqual(tasks?.first?.dictionaryValue?["type"]?.stringValue, "processing")
    }

    func testCompleteTask() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["completeTask"]!

        let result = try await handler([
            "taskId": .string("sync-data"),
            "success": .bool(true),
        ])
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(provider.lastCompletedTaskId, "sync-data")
        XCTAssertEqual(provider.lastCompletedSuccess, true)
    }

    func testCompleteTaskDefaultSuccess() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["completeTask"]!

        _ = try await handler(["taskId": .string("sync-data")])
        XCTAssertEqual(provider.lastCompletedSuccess, true)
    }

    func testCompleteTaskMissingTaskId() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["completeTask"]!

        do {
            _ = try await handler([:])
            XCTFail("Expected error for missing taskId")
        } catch let error as RynBridgeError {
            XCTAssertEqual(error.code, .invalidMessage)
        }
    }

    func testRequestPermission() async throws {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        let handler = module.actions["requestPermission"]!

        let result = try await handler([:])
        XCTAssertEqual(result["granted"]?.boolValue, true)
    }

    func testModuleNameAndVersion() {
        let provider = MockBackgroundTaskProvider()
        let module = BackgroundTaskModule(provider: provider)
        XCTAssertEqual(module.name, "backgroundTask")
        XCTAssertEqual(module.version, "0.1.0")
    }

    func testEndToEndWithBridge() async throws {
        let transport = MockTransport()
        let bridge = RynBridge(transport: transport, config: BridgeConfig(timeout: 5.0))
        let provider = MockBackgroundTaskProvider()
        bridge.register(BackgroundTaskModule(provider: provider))

        let requestJSON = """
        {"id":"req-1","module":"backgroundTask","action":"requestPermission","payload":{},"version":"0.1.0"}
        """
        transport.simulateIncoming(requestJSON)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(transport.sent.count, 1)
        let response = try JSONDecoder().decode(BridgeResponse.self, from: transport.sent[0].data(using: .utf8)!)
        XCTAssertEqual(response.id, "req-1")
        XCTAssertEqual(response.status, .success)
        XCTAssertEqual(response.payload["granted"]?.boolValue, true)

        bridge.dispose()
    }
}

private final class MockBackgroundTaskProvider: BackgroundTaskProvider, @unchecked Sendable {
    var lastScheduledTaskId: String?
    var lastScheduledType: String?
    var lastScheduledInterval: Int?
    var lastScheduledDelay: Int?
    var lastScheduledRequiresNetwork: Bool?
    var lastScheduledRequiresCharging: Bool?
    var lastCancelledTaskId: String?
    var cancelAllTasksCalled = false
    var lastCompletedTaskId: String?
    var lastCompletedSuccess: Bool?

    func scheduleTask(taskId: String, type: String, interval: Int?, delay: Int?, requiresNetwork: Bool, requiresCharging: Bool) async throws -> Bool {
        lastScheduledTaskId = taskId
        lastScheduledType = type
        lastScheduledInterval = interval
        lastScheduledDelay = delay
        lastScheduledRequiresNetwork = requiresNetwork
        lastScheduledRequiresCharging = requiresCharging
        return true
    }

    func cancelTask(taskId: String) async throws -> Bool {
        lastCancelledTaskId = taskId
        return true
    }

    func cancelAllTasks() async throws -> Bool {
        cancelAllTasksCalled = true
        return true
    }

    func getScheduledTasks() async throws -> [[String: AnyCodable]] {
        [["taskId": .string("sync-data"), "type": .string("processing"), "status": .string("scheduled")]]
    }

    func completeTask(taskId: String, success: Bool) {
        lastCompletedTaskId = taskId
        lastCompletedSuccess = success
    }

    func requestPermission() async throws -> Bool {
        true
    }
}
