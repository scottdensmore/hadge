import UIKit

class AccountCell: UITableViewCell {
    let avatarView = UIImageView()
    let nameLabel = UILabel()
    let loginLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: 15.0, bottom: 0, right: 0)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 17
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = UIColor.init(red: 27/255, green: 27/255, blue: 27/255, alpha: 1)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 0

        loginLabel.translatesAutoresizingMaskIntoConstraints = false
        loginLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        loginLabel.textColor = UIColor.secondaryLabel
        loginLabel.numberOfLines = 0

        let labelsStack = UIStackView(arrangedSubviews: [nameLabel, loginLabel])
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical
        labelsStack.alignment = .leading
        labelsStack.spacing = 2

        contentView.addSubview(avatarView)
        contentView.addSubview(labelsStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 34),
            avatarView.heightAnchor.constraint(equalToConstant: 34),

            labelsStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            labelsStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            labelsStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            labelsStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
