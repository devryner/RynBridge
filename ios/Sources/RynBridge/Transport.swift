import Foundation

public protocol Transport: AnyObject, Sendable {
    func send(_ message: String)
    func onMessage(_ handler: @escaping @Sendable (String) -> Void)
    func dispose()
}
