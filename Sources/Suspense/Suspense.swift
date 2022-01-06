import SwiftUI

public struct Suspense<
  Data,
  Success: View,
  Loading: View,
  Failure: View
>: View {

  public struct RetryAction {
    let action: () -> Void

    func callAsFunction() {
      action()
    }
  }

  enum Phase {
    case loading
    case success(Data)
    case failure(Error)
  }

  let fetchData: () async throws -> Data
  let success: (Data) -> Success
  let loading: () -> Loading
  let failure: (Error, RetryAction) -> Failure

  @State var phase = Phase.loading

  var retryAction: RetryAction {
    RetryAction { phase = .loading }
  }

  public var body: some View {
    Group {
      switch phase {
      case .loading:
        loading()
          .task {
            do {
              let data = try await fetchData()
              phase = .success(data)
            } catch {
              phase = .failure(error)
            }
          }
      case .success(let data):
        success(data)
      case .failure(let error):
        failure(error, retryAction)
      }
    }
  }
}

struct Suspense_Previews: PreviewProvider {

  static var previews: some View {
    Suspense {
      let url = URL(string: "https://api.github.com/zen")!
      try await Task.sleep(nanoseconds: 3_000_000_000)
      let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
      return String(data: data, encoding: .utf8) ?? ""
    } success: { (text: String) in
      Text(text)
    } loading: {
      ProgressView()
    } failure: { error, retry in
      Button {
        retry()
      } label: {
        Text("Retry")
      }
    }
  }
}
