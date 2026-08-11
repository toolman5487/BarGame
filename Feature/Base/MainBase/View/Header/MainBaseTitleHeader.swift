//
//  MainBaseTitleHeader.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

@MainActor
class MainBaseTitleHeader: UICollectionReusableView {

    // MARK: - Reuse

    static var reuseIdentifier: String {
        String(describing: Self.self)
    }

    static let elementKind = UICollectionView.elementKindSectionHeader

    // MARK: - Layout

    enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let preferredHeight: CGFloat = 44
    }

    // MARK: - UI Elements

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
        setAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(title: String) {
        titleLabel.text = title
    }

    // MARK: - Overridable

    func setHierarchy() {
        addSubview(titleLabel)
    }

    func setLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.top.equalToSuperview().inset(Layout.verticalInset)
            make.bottom.equalToSuperview().inset(Layout.verticalInset)
        }
    }

    func setAppearance() {
        backgroundColor = .clear
    }
}

// MARK: - UICollectionView Helpers

extension UICollectionView {

    func register(_ headerType: MainBaseTitleHeader.Type) {
        register(
            headerType,
            forSupplementaryViewOfKind: headerType.elementKind,
            withReuseIdentifier: headerType.reuseIdentifier
        )
    }

    func dequeueReusableHeader<Header: MainBaseTitleHeader>(
        _ headerType: Header.Type,
        for indexPath: IndexPath
    ) -> Header {
        guard let header = dequeueReusableSupplementaryView(
            ofKind: headerType.elementKind,
            withReuseIdentifier: headerType.reuseIdentifier,
            for: indexPath
        ) as? Header else {
            preconditionFailure("Unable to dequeue \(headerType.reuseIdentifier)")
        }
        return header
    }
}
