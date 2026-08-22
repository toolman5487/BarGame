//
//  RoundDetailInformationCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import SnapKit
import UIKit

@MainActor
final class RoundDetailInformationCell: DetailBaseCollectionViewCell {

    private enum Metrics {
        static let verticalInset: CGFloat = 4
        static let contentInset: CGFloat = 16
        static let rowHeight: CGFloat = 48
    }

    private let backgroundButton = ViewFactory.makeButton()
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.isUserInteractionEnabled = false
        return stackView
    }()

    static func preferredHeight(itemCount: Int) -> CGFloat {
        Metrics.verticalInset * 2
            + Metrics.contentInset * 2
            + CGFloat(itemCount) * Metrics.rowHeight
    }

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
        contentView.addSubview(contentStackView)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundButton).inset(Metrics.contentInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeInformationRows()
    }

    func configure(items: [RoundDetailInformationItem]) {
        removeInformationRows()
        for item in items {
            contentStackView.addArrangedSubview(
                RoundDetailInformationRow(item: item)
            )
        }
    }

    private func removeInformationRows() {
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

@MainActor
private final class RoundDetailInformationRow: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.primary
        label.textAlignment = .right
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingHead
        return label
    }()

    init(item: RoundDetailInformationItem) {
        super.init(frame: .zero)
        titleLabel.text = item.title
        valueLabel.text = item.value
        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(16)
            make.right.centerY.equalToSuperview()
        }
        titleLabel.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
