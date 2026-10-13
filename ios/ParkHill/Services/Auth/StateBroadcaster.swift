import os

/// Holds a current value and streams it, then every change, to any number of
/// listeners. Repeated identical values are not re-emitted.
final class StateBroadcaster<Value: Equatable & Sendable>: Sendable {
    private struct State {
        var value: Value
        var continuations: [Int: AsyncStream<Value>.Continuation] = [:]
        var nextID = 0
    }

    private let state: OSAllocatedUnfairLock<State>

    init(_ initial: Value) {
        state = OSAllocatedUnfairLock(initialState: State(value: initial))
    }

    var value: Value {
        state.withLock { $0.value }
    }

    func send(_ value: Value) {
        let continuations = state.withLock { state -> [AsyncStream<Value>.Continuation] in
            guard state.value != value else { return [] }
            state.value = value
            return Array(state.continuations.values)
        }
        continuations.forEach { $0.yield(value) }
    }

    func stream() -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream<Value>.makeStream()
        let id = state.withLock { state in
            let id = state.nextID
            state.nextID += 1
            state.continuations[id] = continuation
            continuation.yield(state.value)
            return id
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { _ = $0.continuations.removeValue(forKey: id) }
        }
        return stream
    }
}
