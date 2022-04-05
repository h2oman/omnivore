import Combine
import Models
import Services
import SwiftUI
import Views

final class LabelsViewModel: ObservableObject {
  private var hasLoadedInitialLabels = false
  @Published var isLoading = false
  @Published var labels = [FeedItemLabel]()
  @Published var showCreateEmailModal = false

  var subscriptions = Set<AnyCancellable>()

  func loadLabels(dataService: DataService) {
    guard !hasLoadedInitialLabels else { return }
    isLoading = true

    dataService.labelsPublisher().sink(
      receiveCompletion: { _ in },
      receiveValue: { [weak self] result in
        self?.isLoading = false
        self?.labels = result
        self?.hasLoadedInitialLabels = true
      }
    )
    .store(in: &subscriptions)
  }

  func createLabel(dataService: DataService, name: String, color: Color, description: String?) {
    isLoading = true

    dataService.createLabelPublisher(
      name: name,
      color: color.hex ?? "",
      description: description
    ).sink(
      receiveCompletion: { [weak self] _ in
        self?.isLoading = false
      },
      receiveValue: { [weak self] result in
        self?.isLoading = false
        self?.labels.insert(result, at: 0)
        self?.showCreateEmailModal = false
      }
    )
    .store(in: &subscriptions)
  }
}

struct LabelsView: View {
  @EnvironmentObject var dataService: DataService
  @StateObject var viewModel = LabelsViewModel()

  let footerText = "Use labels to create curated collections of links."

  var body: some View {
    Group {
      #if os(iOS)
        Form {
          innerBody
        }
      #elseif os(macOS)
        List {
          innerBody
        }
        .listStyle(InsetListStyle())
      #endif
    }
    .onAppear { viewModel.loadLabels(dataService: dataService) }
  }

  private var innerBody: some View {
    Group {
      Section(footer: Text(footerText)) {
        Button(
          action: { viewModel.showCreateEmailModal = true },
          label: {
            HStack {
              Image(systemName: "plus.circle.fill").foregroundColor(.green)
              Text("Create a new Label")
              Spacer()
            }
          }
        )
        .disabled(viewModel.isLoading)
      }

      if !viewModel.labels.isEmpty {
        Section(header: Text("Labels")) {
          ForEach(viewModel.labels, id: \.id) { label in
            Text(label.name)
          }
        }
      }
    }
    .navigationTitle("Labels")
    .sheet(isPresented: $viewModel.showCreateEmailModal) {
      CreateLabelView(viewModel: viewModel)
    }
  }
}

struct CreateLabelView: View {
  @EnvironmentObject var dataService: DataService
  @ObservedObject var viewModel: LabelsViewModel

  @State private var newLabelName = ""
  @State private var newLabelColor = Color.clear

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {
        TextField("Label Name", text: $newLabelName)
          .keyboardType(.alphabet)
          .textFieldStyle(StandardTextFieldStyle())
        ColorPicker(
          newLabelColor == .clear ? "Select Color" : newLabelColor.description,
          selection: $newLabelColor
        )
        Button(
          action: {
            viewModel.createLabel(
              dataService: dataService,
              name: newLabelName,
              color: newLabelColor,
              description: nil
            )
          },
          label: { Text("Create") }
        )
        .buttonStyle(SolidCapsuleButtonStyle(color: .appDeepBackground, width: 300))
        .disabled(viewModel.isLoading || newLabelName.isEmpty || newLabelColor == .clear)
        Spacer()
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button(
            action: { viewModel.showCreateEmailModal = false },
            label: {
              Image(systemName: "xmark")
                .foregroundColor(.appGrayTextContrast)
            }
          )
        }
      }
      .navigationTitle("Create New Label")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
