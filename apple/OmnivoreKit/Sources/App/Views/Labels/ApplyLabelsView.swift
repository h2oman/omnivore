import Models
import Services
import SwiftUI
import Views

struct ApplyLabelsView: View {
  enum Mode {
    case item(FeedItem)
    case list([FeedItemLabel])

    var navTitle: String {
      switch self {
      case .item:
        return "Assign Labels"
      case .list:
        return "Apply Label Filters"
      }
    }

    var confirmButtonText: String {
      switch self {
      case .item:
        return "Save"
      case .list:
        return "Apply"
      }
    }
  }

  let mode: Mode
  let commitLabelChanges: ([FeedItemLabel]) -> Void

  @EnvironmentObject var dataService: DataService
  @Environment(\.presentationMode) private var presentationMode
  @StateObject var viewModel = LabelsViewModel()
  @State private var labelSearchFilter = ""

  var innerBody: some View {
    List {
      Section(header: Text("Assigned Labels")) {
        if viewModel.selectedLabels.isEmpty {
          Text("No labels are currently assigned.")
        }
        ForEach(viewModel.selectedLabels.applySearchFilter(labelSearchFilter), id: \.self) { label in
          HStack {
            TextChip(feedItemLabel: label)
            Spacer()
            Button(
              action: {
                withAnimation {
                  viewModel.removeLabelFromItem(label)
                }
              },
              label: { Image(systemName: "xmark.circle").foregroundColor(.appGrayTextContrast) }
            )
          }
        }
      }
      Section(header: Text("Available Labels")) {
        ForEach(viewModel.unselectedLabels.applySearchFilter(labelSearchFilter), id: \.self) { label in
          HStack {
            TextChip(feedItemLabel: label)
            Spacer()
            Button(
              action: {
                withAnimation {
                  viewModel.addLabelToItem(label)
                }
              },
              label: { Image(systemName: "plus").foregroundColor(.appGrayTextContrast) }
            )
          }
        }
      }
      Section {
        Button(
          action: { viewModel.showCreateEmailModal = true },
          label: {
            HStack {
              Image(systemName: "plus.circle.fill").foregroundColor(.green)
              Text("Create a new Label").foregroundColor(.appGrayTextContrast)
              Spacer()
            }
          }
        )
        .disabled(viewModel.isLoading)
      }
    }
    .navigationTitle(mode.navTitle)
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(
            action: { presentationMode.wrappedValue.dismiss() },
            label: { Text("Cancel").foregroundColor(.appGrayTextContrast) }
          )
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(
            action: {
              switch mode {
              case let .item(feedItem):
                viewModel.saveItemLabelChanges(itemID: feedItem.id, dataService: dataService) { labels in
                  commitLabelChanges(labels)
                  presentationMode.wrappedValue.dismiss()
                }
              case .list:
                commitLabelChanges(viewModel.selectedLabels)
                presentationMode.wrappedValue.dismiss()
              }
            },
            label: { Text(mode.confirmButtonText).foregroundColor(.appGrayTextContrast) }
          )
        }
      }
    #endif
    .sheet(isPresented: $viewModel.showCreateEmailModal) {
      CreateLabelView(viewModel: viewModel)
    }
  }

  var body: some View {
    NavigationView {
      if viewModel.isLoading {
        EmptyView()
      } else {
        #if os(iOS)
          if #available(iOS 15.0, *) {
            innerBody
              .searchable(
                text: $labelSearchFilter,
                placement: .navigationBarDrawer(displayMode: .always)
              )
          } else {
            innerBody
          }
        #else
          innerBody
        #endif
      }
    }
    .onAppear {
      switch mode {
      case let .item(feedItem):
        viewModel.loadLabels(dataService: dataService, item: feedItem)
      case let .list(labels):
        viewModel.loadLabels(dataService: dataService, initiallySelectedLabels: labels)
      }
    }
  }
}

private extension Sequence where Element == FeedItemLabel {
  func applySearchFilter(_ searchFilter: String) -> [FeedItemLabel] {
    if searchFilter.isEmpty {
      return map { $0 } // return the identity of the sequence
    }
    return filter { $0.name.lowercased().contains(searchFilter.lowercased()) }
  }
}
