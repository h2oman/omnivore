import Combine
import Models
import Services
import SwiftUI

final class ApplyLabelsViewModel: ObservableObject {
  private var hasLoadedInitialLabels = false
  @Published var isLoading = true
  @Published var selectedLabels = Set<FeedItemLabel>()
  @Published var labels = [FeedItemLabel]()

  var subscriptions = Set<AnyCancellable>()

  func load(item: FeedItem, dataService: DataService) {
    guard !hasLoadedInitialLabels else { return }

    dataService.labelsPublisher().sink(
      receiveCompletion: { _ in },
      receiveValue: { [weak self] result in
        self?.isLoading = false
        self?.labels = result
        self?.hasLoadedInitialLabels = true
        self?.selectedLabels = Set(item.labels)
      }
    )
    .store(in: &subscriptions)
  }
}

struct ApplyLabelsView: View {
  let item: FeedItem
  @EnvironmentObject var dataService: DataService
  @Environment(\.presentationMode) private var presentationMode
  @StateObject var viewModel = ApplyLabelsViewModel()

  var body: some View {
    NavigationView {
      if viewModel.isLoading {
        EmptyView()
      } else {
        List(viewModel.labels, id: \.self, selection: $viewModel.selectedLabels) { label in
          Text(label.name)
        }
        .environment(\.editMode, .constant(EditMode.active))
        .navigationTitle("Apply Labels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button(
              action: { presentationMode.wrappedValue.dismiss() },
              label: { Text("Cancel") }
            )
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(
              action: {
                print("saving")
                presentationMode.wrappedValue.dismiss()
              },
              label: { Text("Save") }
            )
          }
        }
      }
    }
    .onAppear {
      viewModel.load(item: item, dataService: dataService)
    }
  }
}
