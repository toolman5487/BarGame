//
//  ViewController.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/2.
//

import UIKit
import SnapKit

@MainActor
final class ViewController: UIViewController {

    // MARK: - Types

    private enum DiceViewMode {
        case perspective
        case topDown
    }

    private enum DiceControl: Int, CaseIterable {
        case lock
        case add
        case action
    }

    private enum ControlLayout {
        static let itemSize: CGFloat = 56
        static let itemSpacing: CGFloat = 12
        static let edgeInset: CGFloat = 16
        static let collectionHeight = itemSize * 3 + itemSpacing * 2
    }

    // MARK: - UI

    private let diceView = GameDiceView()
    private lazy var controlCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(
            width: ControlLayout.itemSize,
            height: ControlLayout.itemSize
        )
        layout.minimumLineSpacing = ControlLayout.itemSpacing

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            DiceControlCollectionViewCell.self,
            forCellWithReuseIdentifier: DiceControlCollectionViewCell.reuseIdentifier
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - State

    private var diceViewMode: DiceViewMode = .perspective
    private var isDiceLocked = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "骰子"
        view.backgroundColor = .systemBackground
        setupViewHierarchy()
        setupViewLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    // MARK: - UIResponder

    override var canBecomeFirstResponder: Bool { true }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake, !isDiceLocked else { return }
        diceView.shake()
    }

    // MARK: - Setup

    private func setupViewHierarchy() {
        view.addSubview(diceView)
        view.addSubview(controlCollectionView)
    }

    private func setupViewLayout() {
        diceView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        controlCollectionView.snp.makeConstraints { make in
            make.right.bottom.equalTo(view.safeAreaLayoutGuide).inset(ControlLayout.edgeInset)
            make.width.equalTo(ControlLayout.itemSize)
            make.height.equalTo(ControlLayout.collectionHeight)
        }
    }

    // MARK: - State Updates

    private func setDiceLocked(_ isLocked: Bool) {
        isDiceLocked = isLocked
        diceView.setInteractionLocked(isLocked)
        controlCollectionView.reloadData()
    }

    // MARK: - Actions

    private func handleAddDiceTap() {
        diceView.addDice()
        controlCollectionView.reloadData()
    }

    private func handleActionButtonTap() {
        switch diceViewMode {
        case .perspective:
            diceView.showTopDownView()
            diceViewMode = .topDown
            setDiceLocked(true)

        case .topDown:
            diceView.showPerspectiveView()
            diceViewMode = .perspective
            setDiceLocked(false)
        }
    }

    private func handleLockButtonTap() {
        guard diceViewMode == .perspective else { return }
        setDiceLocked(!isDiceLocked)
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        DiceControl.allCases.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let control = DiceControl(rawValue: indexPath.item),
              let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DiceControlCollectionViewCell.reuseIdentifier,
                for: indexPath
              ) as? DiceControlCollectionViewCell else {
            return UICollectionViewCell()
        }

        configure(cell, for: control)
        return cell
    }

    private func configure(
        _ cell: DiceControlCollectionViewCell,
        for control: DiceControl
    ) {
        switch control {
        case .lock:
            configureLockControl(cell)
        case .add:
            configureAddControl(cell)
        case .action:
            configureActionControl(cell)
        }
    }

    private func configureLockControl(_ cell: DiceControlCollectionViewCell) {
        let isEnabled = diceViewMode == .perspective
        cell.configure(
            image: UIImage(systemName: isDiceLocked ? "lock.fill" : "lock.open"),
            foregroundColor: isDiceLocked ? .systemOrange : .label,
            isEnabled: isEnabled
        )
    }

    private func configureActionControl(_ cell: DiceControlCollectionViewCell) {
        let imageName: String

        switch diceViewMode {
        case .perspective:
            imageName = "checkmark"
        case .topDown:
            imageName = "arrow.backward"
        }

        cell.configure(
            image: UIImage(systemName: imageName),
            foregroundColor: .label,
            isEnabled: true
        )
    }

    private func configureAddControl(_ cell: DiceControlCollectionViewCell) {
        let canAddDice = diceView.canAddDice

        cell.configure(
            image: UIImage(systemName: "plus"),
            foregroundColor: .label,
            isEnabled: canAddDice
        )
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let control = DiceControl(rawValue: indexPath.item) else { return }

        switch control {
        case .lock:
            handleLockButtonTap()
        case .add:
            handleAddDiceTap()
        case .action:
            handleActionButtonTap()
        }
    }
}

// MARK: - DiceControlCollectionViewCell

private final class DiceControlCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: DiceControlCollectionViewCell.self)

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.isUserInteractionEnabled = false
        return button
    }()

    override var isHighlighted: Bool {
        didSet {
            button.isHighlighted = isHighlighted
        }
    }

    override var isSelected: Bool {
        didSet {
            button.isSelected = isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        image: UIImage?,
        foregroundColor: UIColor,
        isEnabled: Bool
    ) {
        var configuration = UIButton.Configuration.glass()
        configuration.cornerStyle = .capsule
        configuration.image = image
        configuration.baseForegroundColor = foregroundColor
        button.configuration = configuration
        button.isEnabled = isEnabled

        isUserInteractionEnabled = isEnabled
    }

    private func setupButton() {
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
