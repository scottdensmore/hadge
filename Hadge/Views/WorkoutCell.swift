import UIKit
import HealthKit

class WorkoutCell: UITableViewCell {
    let titleLabel = UILabel()
    let emojiLabel = UILabel()
    let dateLabel = UILabel()
    let distanceLabel = UILabel()
    let durationLabel = UILabel()
    let energyLabel = UILabel()
    let sourceLabel = UILabel()

    private let emojiContainer = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        emojiLabel.text = nil
        dateLabel.text = nil
        distanceLabel.text = nil
        durationLabel.text = nil
        energyLabel.text = nil
        sourceLabel.text = nil
    }

    private func configureView() {
        configureCellStyle()
        configureLabelStyles()
        let contentStack = buildContentStack()
        installHierarchy(contentStack: contentStack)
        activateConstraints(contentStack: contentStack)
    }

    private func configureCellStyle() {
        accessoryType = .disclosureIndicator
        selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 0)

        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.layer.cornerRadius = 17
        emojiContainer.backgroundColor = UIColor.tertiarySystemFill

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = UIFont.systemFont(ofSize: 20)
        emojiLabel.textAlignment = .center
    }

    private func configureLabelStyles() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 1

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        dateLabel.textColor = UIColor.secondaryLabel
        dateLabel.numberOfLines = 1

        distanceLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        distanceLabel.textColor = UIColor.secondaryLabel
        durationLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        durationLabel.textColor = UIColor.secondaryLabel
        energyLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        energyLabel.textColor = UIColor.secondaryLabel
        sourceLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        sourceLabel.textColor = UIColor.secondaryLabel
    }

    private func buildContentStack() -> UIStackView {
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.axis = .vertical
        titleStack.spacing = 2
        titleStack.alignment = .leading

        let detailStack = UIStackView(arrangedSubviews: [distanceLabel, durationLabel, energyLabel, sourceLabel])
        detailStack.translatesAutoresizingMaskIntoConstraints = false
        detailStack.axis = .horizontal
        detailStack.spacing = 8
        detailStack.alignment = .center
        detailStack.distribution = .fillProportionally

        let contentStack = UIStackView(arrangedSubviews: [titleStack, detailStack])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 4
        contentStack.alignment = .leading
        return contentStack
    }

    private func installHierarchy(contentStack: UIStackView) {
        contentView.addSubview(emojiContainer)
        emojiContainer.addSubview(emojiLabel)
        contentView.addSubview(contentStack)
    }

    private func activateConstraints(contentStack: UIStackView) {
        NSLayoutConstraint.activate([
            emojiContainer.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            emojiContainer.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            emojiContainer.widthAnchor.constraint(equalToConstant: 34),
            emojiContainer.heightAnchor.constraint(equalToConstant: 34),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),

            contentStack.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    func setStartDate(_ date: Date) {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        dateLabel.text = formatter.localizedString(for: date, relativeTo: Date())
    }

    func setDistance(_ distance: HKQuantity?) {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1

        if let meters = distance?.doubleValue(for: HKUnit.meter()), meters > 0 {
            distanceLabel.text = formatter.string(fromValue: meters / 1000, unit: .kilometer)
        } else {
            distanceLabel.text = ""
        }
    }

    func setDuration(_ duration: TimeInterval) {
        let time = NSInteger(duration)

        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        durationLabel.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }

    func setEnergy(_ energy: HKQuantity?) {
        if let calories = energy?.doubleValue(for: HKUnit.kilocalorie()) {
            energyLabel.text = String(format: "%0.0fcal", calories)
        } else {
            energyLabel.text = String(format: "")
        }
    }
}
