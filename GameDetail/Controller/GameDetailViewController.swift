//
//  GameDetailViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import UIKit

@MainActor
final class GameDetailViewController: DetailBaseViewController {

    // MARK: - Dependencies

    private let game: DiceGame
    private lazy var router: any GameDetailRouting = GameDetailRouter(
        sourceViewController: self
    )

    // MARK: - State

    private let sections: [GameDetailSection]

    // MARK: - Lifecycle

    init(
        game: DiceGame,
        sections: [GameDetailSection]? = nil
    ) {
        self.game = game
        self.sections = sections ?? GameDetailSection.standard(for: game.id)
        super.init(title: game.title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridable

    override func setHierarchy() {
        super.setHierarchy()
        collectionView.dataSource = self
        collectionView.register(GameDetailRuleCell.self)
        collectionView.register(GameDetailStartCell.self)
        collectionView.register(GameDetailTitleHeader.self)
    }

    override func collectionViewHeaderSize(
        in collectionView: UICollectionView,
        section: Int
    ) -> CGSize {
        guard sections.indices.contains(section),
              sections[section].headerTitle != nil
        else { return .zero }

        return CGSize(
            width: collectionView.bounds.width,
            height: GameDetailTitleHeader.Metrics.preferredHeight
        )
    }

    // MARK: - Actions

    private func startGame() {
        router.route(to: .startGame(game.id))
    }
}

// MARK: - UICollectionViewDataSource

extension GameDetailViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard sections.indices.contains(section) else { return 0 }

        switch sections[section] {
        case .rules(let rules):
            return rules.count

        case .settings:
            return 0

        case .start:
            return 1
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard sections.indices.contains(indexPath.section) else {
            preconditionFailure("Invalid GameDetail section index: \(indexPath.section)")
        }

        switch sections[indexPath.section] {
        case .rules(let rules):
            guard rules.indices.contains(indexPath.item) else {
                preconditionFailure("Invalid GameDetail rule index: \(indexPath.item)")
            }

            let cell = collectionView.dequeueReusableCell(
                GameDetailRuleCell.self,
                for: indexPath
            )
            cell.configure(rule: rules[indexPath.item])
            return cell

        case .settings:
            preconditionFailure(
                "GameDetail section does not provide a cell: \(indexPath.section)"
            )

        case .start:
            let cell = collectionView.dequeueReusableCell(
                GameDetailStartCell.self,
                for: indexPath
            )
            cell.configure(title: "進入遊戲")
            cell.tapHandler = { [weak self] in
                self?.startGame()
            }
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == GameDetailTitleHeader.elementKind,
              sections.indices.contains(indexPath.section),
              let title = sections[indexPath.section].headerTitle
        else { return UICollectionReusableView() }

        let header = collectionView.dequeueReusableHeader(
            GameDetailTitleHeader.self,
            for: indexPath
        )
        header.configure(title: title)
        return header
    }
}
