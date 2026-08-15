//
//  MainGameHistoryFilterHeader.swift
//  BarGame
//
//  Created by Codex on 2026/8/15.
//

import SnapKit
import UIKit

@MainActor
final class MainGameHistoryFilterHeader: StandardBaseTitleHeader {

    // MARK: - Layout

    enum Layout {
        static let preferredHeight: CGFloat = 64
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let spacing: CGFloat = 8
    }

    // MARK: - Callback

    private var changeHandler: ((MainGameHistoryFilterChange) -> Void)?

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        return scrollView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = Layout.spacing
        return stackView
    }()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        changeHandler = nil
        removeGameButtons()
    }

    // MARK: - Overridable

    override func setHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(buttonStackView)
    }

    override func setLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        buttonStackView.snp.makeConstraints { make in
            make.left.right.equalTo(scrollView.contentLayoutGuide)
                .inset(Layout.horizontalInset)
            make.top.bottom.equalTo(scrollView.frameLayoutGuide)
                .inset(Layout.verticalInset)
        }
    }

    override func setAppearance() {
        backgroundColor = .systemBackground
    }

    // MARK: - Configuration

    func configure(
        filter: MainGameHistoryFilter,
        changeHandler: @escaping (MainGameHistoryFilterChange) -> Void
    ) {
        self.changeHandler = changeHandler
        removeGameButtons()

        addGameButton(
            title: "全部遊戲",
            gameID: nil,
            isSelected: filter.gameID == nil
        )
        DiceGameID.allCases.forEach { gameID in
            addGameButton(
                title: gameID.title,
                gameID: gameID,
                isSelected: filter.gameID == gameID
            )
        }
    }

    // MARK: - Private

    private func addGameButton(
        title: String,
        gameID: DiceGameID?,
        isSelected: Bool
    ) {
        let action = UIAction(title: title) { [weak self] _ in
            self?.changeHandler?(.game(gameID))
        }
        let button = UIButton(primaryAction: action)
        var configuration = UIButton.Configuration.prominentGlass()
        configuration.title = title
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = isSelected ? .label : .clear
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 12,
            bottom: 8,
            trailing: 12
        )
        button.configuration = configuration
        button.tintColor = isSelected ? .systemBackground : .secondaryLabel
        buttonStackView.addArrangedSubview(button)
    }

    private func removeGameButtons() {
        buttonStackView.arrangedSubviews.forEach { view in
            buttonStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
