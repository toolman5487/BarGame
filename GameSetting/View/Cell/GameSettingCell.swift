//
//  GameSettingCell.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/13.
//

import SnapKit
import UIKit

@MainActor
final class GameSettingCell: DetailBaseCollectionViewCell {

    // MARK: - Metrics

    private enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let contentSpacing: CGFloat = 12
        static let settingContentSpacing: CGFloat = 8
        static let controlSize: CGFloat = 44
        static let titleWidth: CGFloat = 72
        static let titleHeight: CGFloat = 44
        static let valueWidth: CGFloat = 44
    }

    // MARK: - Callback

    var valueChanged: ((Int) -> Void)?

    // MARK: - State

    private var currentValue = 1
    private var allowedRange: ClosedRange<Int>?

    // MARK: - UI Elements

    private let titleLabelView = ViewFactory.makeGlassLabel(
        textStyle: .body,
        textAlignment: .center,
        numberOfLines: 1,
        contentInsets: .zero
    )

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
            weight: .regular
        )
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        return label
    }()

    private let decreaseButton = ViewFactory.makeIconButton(systemName: "minus")
    private let increaseButton = ViewFactory.makeIconButton(systemName: "plus")

    private lazy var settingStackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [decreaseButton, valueLabel, increaseButton]
        )
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Metrics.settingContentSpacing
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(titleLabelView)
        contentView.addSubview(settingStackView)
    }

    override func setLayout() {
        titleLabelView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Metrics.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(Metrics.titleWidth)
            make.height.equalTo(Metrics.titleHeight)
        }

        settingStackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left
                .greaterThanOrEqualTo(titleLabelView.snp.right)
                .offset(Metrics.contentSpacing)
            make.right.equalToSuperview().inset(Metrics.horizontalInset)
        }

        decreaseButton.snp.makeConstraints { make in
            make.size.equalTo(Metrics.controlSize)
        }

        valueLabel.snp.makeConstraints { make in
            make.width.equalTo(Metrics.valueWidth)
        }

        increaseButton.snp.makeConstraints { make in
            make.size.equalTo(Metrics.controlSize)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .clear
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        decreaseButton.addAction(
            UIAction { [weak self] _ in
                self?.adjustValue(by: -1)
            },
            for: .primaryActionTriggered
        )
        increaseButton.addAction(
            UIAction { [weak self] _ in
                self?.adjustValue(by: 1)
            },
            for: .primaryActionTriggered
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabelView.configure(text: nil)
        valueLabel.text = nil
        currentValue = 1
        allowedRange = nil
        decreaseButton.isEnabled = false
        increaseButton.isEnabled = false
        valueChanged = nil
    }

    // MARK: - Configuration

    func configure(setting: GameSetting) {
        switch setting {
        case .diceCount(let value, let allowedRange):
            titleLabelView.configure(text: "骰子數")
            currentValue = value
            self.allowedRange = allowedRange
            updateControlState()
        }
    }

    // MARK: - Actions

    private func adjustValue(by difference: Int) {
        guard let allowedRange else { return }
        let updatedValue = currentValue + difference
        guard allowedRange.contains(updatedValue) else { return }
        currentValue = updatedValue
        updateControlState()
        valueChanged?(updatedValue)
    }

    private func updateControlState() {
        guard let allowedRange else {
            valueLabel.text = nil
            decreaseButton.isEnabled = false
            increaseButton.isEnabled = false
            return
        }

        valueLabel.text = "\(currentValue) 顆"
        decreaseButton.isEnabled = currentValue > allowedRange.lowerBound
        increaseButton.isEnabled = currentValue < allowedRange.upperBound
    }
}
