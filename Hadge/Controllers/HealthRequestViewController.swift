import UIKit
import SwiftUI
import HealthKit

private enum HealthAccessRequestResult {
    case proceed
    case openHealthApp
    case failed(String)
}

private enum HealthAccessRequester {
    static func requestAccess(completionHandler: @escaping (HealthAccessRequestResult) -> Void) {
        guard HKHealthStore.isHealthDataAvailable(),
              let healthStore = Health.shared().healthStore else {
            completionHandler(.failed("Health data is not available on this device."))
            return
        }

        let objectTypes = requestedObjectTypes()
        healthStore.getRequestStatusForAuthorization(toShare: [], read: objectTypes) { status, _ in
            switch status {
            case .shouldRequest:
                healthStore.requestAuthorization(toShare: [], read: objectTypes) { _, _ in
                    completionHandler(.proceed)
                }
            case .unnecessary:
                completionHandler(.proceed)
            case .unknown:
                completionHandler(.openHealthApp)
            @unknown default:
                completionHandler(.openHealthApp)
            }
        }
    }

    static func openHealthApp() {
        DispatchQueue.main.async {
            guard let url = URL(string: "x-apple-health://") else { return }
            UIApplication.shared.open(url)
        }
    }

    static func requestedObjectTypes() -> Set<HKObjectType> {
        var objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]

        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned,
            .basalEnergyBurned,
            .distanceCycling,
            .distanceDownhillSnowSports,
            .distanceSwimming,
            .distanceWalkingRunning,
            .distanceWheelchair,
            .flightsClimbed,
            .heartRate,
            .stepCount,
            .swimmingStrokeCount
        ]

        for identifier in quantityTypes {
            guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { continue }
            objectTypes.insert(type)
        }

        if let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            objectTypes.insert(biologicalSexType)
        }

        return objectTypes
    }
}

final class HealthAccessViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var statusMessage: String?

    func requestHealthAccess() {
        guard !isLoading else { return }

        isLoading = true
        statusMessage = nil

        HealthAccessRequester.requestAccess { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .proceed:
                    NotificationCenter.default.post(name: .didReceiveHealthAccess, object: nil)
                case .openHealthApp:
                    self.statusMessage = "Please review your Health permissions in the Health app."
                    HealthAccessRequester.openHealthApp()
                case .failed(let message):
                    self.statusMessage = message
                }
            }
        }
    }

    func openHealthApp() {
        HealthAccessRequester.openHealthApp()
    }
}

struct HealthAccessView: View {
    @ObservedObject var viewModel: HealthAccessViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.14), Color(red: 0.18, green: 0.12, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.white)

                        Text("Connect Health")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Hadge needs read-only access to export your workouts, activity, and distance data to your private GitHub repository.")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Read-only Health data access", systemImage: "lock.shield")
                        Label("No third-party tracking", systemImage: "eye.slash")
                        Label("Export goes directly to your GitHub", systemImage: "arrow.up.doc")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button(action: viewModel.requestHealthAccess) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }

                            Text(viewModel.isLoading ? "Checking Access..." : "Enable Health Access")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.91, green: 0.36, blue: 0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(viewModel.isLoading)

                    Button("Open Health App") {
                        viewModel.openHealthApp()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)

                    if let statusMessage = viewModel.statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 36)
            }
        }
    }
}

class HealthRequestViewController: EntireViewController {
    @IBOutlet weak var healthButton: UIButton?

    private let viewModel = HealthAccessViewModel()
    private var hostingController: UIHostingController<HealthAccessView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        embedSwiftUIView()
    }

    @IBAction func requestHealthAccess(_ sender: Any) {
        viewModel.requestHealthAccess()
    }

    private func embedSwiftUIView() {
        let hostingController = UIHostingController(rootView: HealthAccessView(viewModel: viewModel))
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }
}
