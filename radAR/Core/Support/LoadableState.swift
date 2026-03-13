import Foundation

enum LoadableState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty(String)
    case failed(AppError)

    var value: Value? {
        guard case let .loaded(value) = self else {
            return nil
        }

        return value
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
