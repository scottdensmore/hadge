// swiftlint:disable file_length
import UIKit
import SwiftUI
import HealthKit
import AuthenticationServices

private struct WindowResolverView: UIViewRepresentable {
    let onResolve: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            onResolve(view.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            onResolve(uiView.window)
        }
    }
}

private final class OnboardingAuthPresenter: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    weak var window: UIWindow?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window {
            return window
        }

        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first

        if let keyWindow = windowScene?.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        return ASPresentationAnchor()
    }
}

private final class OnboardingLoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var statusMessage: String?
    @Published var token: String = ""
    @Published var showTokenPrompt = false

    private var signInFailedObserver: NSObjectProtocol?

    init() {
        signInFailedObserver = NotificationCenter.default.addObserver(
            forName: .signInFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLoading = false
            self?.statusMessage = "Sign in failed. Please try again."
        }
    }

    deinit {
        if let signInFailedObserver {
            NotificationCenter.default.removeObserver(signInFailedObserver)
        }
    }

    func signIn(with presenter: ASWebAuthenticationPresentationContextProviding?) {
        guard !isLoading else { return }
        statusMessage = nil

        if GitHub.shared().isSignedIn() {
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            return
        }

        isLoading = true
        GitHub.shared().signIn(presenter)
    }

    func saveToken() {
        let cleanedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedToken.isEmpty else {
            statusMessage = "Please enter a valid token."
            return
        }

        GitHub.shared().storeToken(token: cleanedToken)
        token = ""
        showTokenPrompt = false
        statusMessage = "Token saved. Tap Sign in with GitHub to continue."
    }
}

private struct OnboardingLoginView: View {
    @StateObject private var viewModel = OnboardingLoginViewModel()
    @StateObject private var authPresenter = OnboardingAuthPresenter()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.08, blue: 0.14), Color(red: 0.23, green: 0.1, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)

                    Text("Connect GitHub")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Sign in with GitHub so Hadge can create and maintain your private export repository.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Button(
                    action: {
                        viewModel.signIn(with: authPresenter)
                    },
                    label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isLoading ? "Opening GitHub..." : "Sign In With GitHub")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                )
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color(red: 0.91, green: 0.36, blue: 0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(viewModel.isLoading)

                if Constants.debug {
                    Button("Use a Personal Access Token") {
                        viewModel.showTokenPrompt = true
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                }

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 36)
        }
        .background(
            WindowResolverView { window in
                authPresenter.window = window
            }
            .allowsHitTesting(false)
        )
        .alert(
            "Use a Personal Access Token",
            isPresented: $viewModel.showTokenPrompt,
            actions: {
                TextField("Paste your token", text: $viewModel.token)
                Button("Cancel", role: .cancel) {
                    viewModel.token = ""
                }
                Button("Save") {
                    viewModel.saveToken()
                }
            },
            message: {
                Text("This option is only for debugging and is not shown in release builds.")
            }
        )
    }
}

private final class OnboardingSetupViewModel: ObservableObject {
    @Published var statusText = "Preparing your initial export..."
    @Published var isRunning = false

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var years: [String: [Any]] = [:]
    private var started = false

    func startIfNeeded() {
        guard !started else { return }
        started = true
        startExport()
    }

    private func startExport() {
        isRunning = true

        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "InitialExport") {
            if let identifier = self.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        }

        setStatus("Preparing your repository...")

        GitHub.shared().getRepository { _ in
            self.setStatus("Updating README...")
            GitHub.shared().updateFile(path: "README.md", content: self.loadReadMeTemplate(), message: "Update README") { _ in
                (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport) { }
            }
        }
    }

    private func collectWorkoutData(completionHandler: @escaping () -> Void) {
        setStatus("Exporting workouts...")
        Health.shared().getWorkoutsForDates(start: nil, end: nil) { workouts in
            self.initializeYears()
            workouts?.forEach { workout in
                guard let workout = workout as? HKWorkout else { return }
                self.addDataToYears(self.yearFromDate(workout.startDate), data: workout)
            }

            Health.shared().exportData(self.years, directory: "workouts", contentHandler: { workouts in
                Health.shared().generateContentForWorkouts(workouts: workouts)
            }, completionHandler: completionHandler)
        }
    }

    private func collectActivityData(completionHandler: @escaping () -> Void) {
        setStatus("Exporting activity summaries...")
        let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1))
        Health.shared().getActivityDataForDates(start: start, end: Health.shared().yesterday) { summaries in
            self.initializeYears()
            summaries?.forEach { summary in
                self.addDataToYears(String(summary.dateComponents(for: Calendar.current).year ?? 0), data: summary)
            }

            Health.shared().exportData(self.years, directory: "activity", contentHandler: { summaries in
                Health.shared().generateContentForActivityData(summaries: summaries)
            }, completionHandler: completionHandler)
        }
    }

    private func collectDistanceData(completionHandler: @escaping () -> Void) {
        setStatus("Exporting distances...")
        guard let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1)),
              let end = Health.shared().today else {
            completionHandler()
            return
        }

        Health.shared().distanceDataSource?.getAllDistances(start: start, end: end) { distances in
            self.initializeYears()
            distances?.forEach { entry in
                guard let date = entry["date"] as? String else { return }
                self.addDataToYears(String(date.prefix(4)), data: entry)
            }

            Health.shared().exportData(self.years, directory: "distances", contentHandler: { distances in
                Health.shared().generateContentForDistances(distances: distances)
            }, completionHandler: completionHandler)
        }
    }

    private func finishExport(completionHandler: @escaping () -> Void) {
        setStatus("Finishing setup...")

        UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
        NotificationCenter.default.post(name: .didSetUpRepository, object: nil)
        BackgroundTaskHelper.shared().registerBackgroundDelivery()

        if let identifier = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(identifier)
            backgroundTaskIdentifier = nil
        }

        DispatchQueue.main.async {
            self.isRunning = false
        }

        completionHandler()
    }

    private func initializeYears() {
        years = [:]
    }

    private func addDataToYears(_ year: String, data: Any) {
        years[year] = years[year] ?? []
        years[year]?.append(data)
    }

    private func yearFromDate(_ date: Date) -> String {
        String(Calendar.current.dateComponents([.year], from: date).year ?? 0)
    }

    private func setStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusText = text
        }
    }

    private func loadReadMeTemplate() -> String {
        if let filepath = Bundle.main.path(forResource: "ReadMeTemplate", ofType: "md"),
           let contents = try? String(contentsOfFile: filepath) {
            return contents
        }

        return "This repo is managed by Hadge."
    }
}

private struct OnboardingSetupView: View {
    @StateObject private var viewModel = OnboardingSetupViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.12, blue: 0.09), Color(red: 0.11, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)

                Text("Initial Export")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Hadge is creating or reusing your private repository and exporting activity, distance, and workout data.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)

                    Text(viewModel.statusText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 36)
        }
        .onAppear {
            viewModel.startIfNeeded()
        }
    }
}

class SetupPageViewController: EntirePageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private lazy var healthAccessViewController: UIViewController = {
        let viewModel = HealthAccessViewModel()
        let view = HealthAccessView(viewModel: viewModel)
        return UIHostingController(rootView: view)
    }()

    private lazy var loginViewController: UIViewController = {
        UIHostingController(rootView: OnboardingLoginView())
    }()

    private lazy var setupExportViewController: UIViewController = {
        UIHostingController(rootView: OnboardingSetupView())
    }()

    lazy var orderedViewControllers = [
        self.healthAccessViewController,
        self.loginViewController
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.isModalInPresentation = true
        self.dataSource = self
        self.delegate = self

        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.35)
        appearance.currentPageIndicatorTintColor = UIColor.white
        self.view.backgroundColor = UIColor.systemBackground

        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }

        addObservers()
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else { return nil }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else { return nil }
        guard orderedViewControllers.count > previousIndex else { return nil }

        return orderedViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else { return nil }

        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count

        guard orderedViewControllersCount != nextIndex else { return nil }
        guard orderedViewControllersCount > nextIndex else { return nil }

        return orderedViewControllers[nextIndex]
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
              let firstViewControllerIndex = orderedViewControllers.firstIndex(of: firstViewController) else {
            return 0
        }

        return firstViewControllerIndex
    }

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(forwardToLoginViewController), name: .didReceiveHealthAccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forwardToSetupViewController), name: .didSignIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forwardToInitialViewController), name: .didSetUpRepository, object: nil)
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .didReceiveHealthAccess, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didSignIn, object: nil)
        NotificationCenter.default.removeObserver(self, name: .didSetUpRepository, object: nil)
    }

    func goToNextPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
    }

    @objc func forwardToLoginViewController() {
        DispatchQueue.main.async {
            self.goToNextPage(animated: true)
        }
    }

    @objc func forwardToSetupViewController() {
        DispatchQueue.main.async {
            for subView in self.view.subviews where subView is UIPageControl {
                subView.isHidden = true
            }

            self.setViewControllers([self.setupExportViewController], direction: .forward, animated: true, completion: nil)
        }
    }

    @objc func forwardToInitialViewController() {
        DispatchQueue.main.async {
            self.removeObservers()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
// swiftlint:enable file_length
