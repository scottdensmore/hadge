import UIKit
import HealthKit

extension WorkoutsViewController {
    func loadData(_ visible: Bool = true) {
        dataLoaded = false
        startRefreshing(visible)
        loadWorkouts(visible)
    }

    func loadWorkouts(_ visible: Bool = true) {
        Health.shared().getWorkoutsForDates(start: nil, end: nil) { workouts in
            self.data = []
            self.allWorkouts = []
            self.availableYears = []
            self.dataLoaded = true

            guard let workouts = workouts, workouts.count > 0 else {
                self.selectedYear = nil
                self.reloadWithEmptyWorkout()
                return
            }

            self.allWorkouts = workouts.compactMap { $0 as? HKWorkout }
            self.availableYears = self.yearsForWorkouts(self.allWorkouts)
            self.selectDefaultYearIfNeeded()
            self.createDataFromWorkouts(workouts: self.allWorkouts)
        }
        BackgroundTaskHelper.shared().handleForegroundFetch()
    }

    func reloadWithEmptyWorkout() {
        DispatchQueue.main.async {
            self.updateYearButton()
            self.stopRefreshing(true)
            self.tableView.reloadSections([ 0 ], with: .automatic)
        }
    }

    func createDataFromWorkouts(workouts: [HKWorkout]) {
        let calendar = Calendar.current
        self.data = []

        workouts.forEach { workout in
            let workoutYear = calendar.component(.year, from: workout.startDate)
            let yearMatches = selectedYear == nil || selectedYear == workoutYear
            let typeMatches = filter.isEmpty || filter.firstIndex(of: workout.workoutActivityType.rawValue) != nil
            if yearMatches && typeMatches {
                data.append([
                    "title": workout.workoutActivityType.name,
                    "workout": workout
                ])
            }
        }

        DispatchQueue.main.async {
            self.updateYearButton()
            self.stopRefreshing(true)
            self.tableView.reloadSections([ 0 ], with: .automatic)
            self.saveState()
        }
    }

    func yearsForWorkouts(_ workouts: [HKWorkout]) -> [Int] {
        let calendar = Calendar.current
        let years = Set(workouts.map { calendar.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    func selectDefaultYearIfNeeded() {
        guard availableYears.count > 0 else {
            selectedYear = nil
            return
        }
        guard let selectedYear = selectedYear, availableYears.firstIndex(of: selectedYear) != nil else {
            self.selectedYear = availableYears.first
            return
        }
    }

    func selectYear(_ year: Int) {
        guard selectedYear != year else { return }
        selectedYear = year
        createDataFromWorkouts(workouts: allWorkouts)
    }

    func updateYearButton() {
        guard let yearButton = yearButton else { return }

        if let selectedYear = selectedYear {
            yearButton.title = String(selectedYear)
            yearButton.tintColor = UIColor.systemBlue
            yearButton.isEnabled = availableYears.count > 1
        } else {
            yearButton.title = "Year"
            yearButton.tintColor = UIColor.secondaryLabel
            yearButton.isEnabled = false
        }
    }

    func shouldPresentSetupFlow() -> Bool {
        !GitHub.shared().isSignedIn() || !UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished)
    }

    func presentSetupFlow(animated: Bool = true) {
        guard !(presentedViewController is SetupPageViewController) else { return }

        let setupPageViewController = SetupPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        setupPageViewController.modalPresentationStyle = .fullScreen
        present(setupPageViewController, animated: animated)
    }
}

extension WorkoutsViewController: FilterDelegate {
    func onFilterSelected(workoutTypes: [UInt]) {
        if !filter.elementsEqual(workoutTypes) {
            filter = workoutTypes
            if filter.isEmpty {
                self.filterButton?.tintColor = UIColor.secondaryLabel
            } else {
                self.filterButton?.tintColor = UIColor.systemBlue
            }
            self.createDataFromWorkouts(workouts: allWorkouts)
            self.saveState()
        }
    }
}
