//
//  BaseEmptyView.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/11.
//

import SnapKit
import UIKit

// MARK: - BaseEmptySymbolEffectLayerMode

enum BaseEmptySymbolEffectLayerMode: Equatable, Sendable {
    case wholeSymbol
    case byLayer
}

// MARK: - BaseEmptySymbolEffectOptions

struct BaseEmptySymbolEffectOptions: Equatable, Sendable {

    var layerMode: BaseEmptySymbolEffectLayerMode
    var isRepeating: Bool
    var speed: Double

    init(
        layerMode: BaseEmptySymbolEffectLayerMode = .wholeSymbol,
        isRepeating: Bool = false,
        speed: Double = 1.0
    ) {
        self.layerMode = layerMode
        self.isRepeating = isRepeating
        self.speed = speed
    }

    static let once = BaseEmptySymbolEffectOptions()
    static let repeating = BaseEmptySymbolEffectOptions(isRepeating: true)
    static let byLayerOnce = BaseEmptySymbolEffectOptions(layerMode: .byLayer)
    static let byLayerRepeating = BaseEmptySymbolEffectOptions(
        layerMode: .byLayer,
        isRepeating: true
    )
}

// MARK: - BaseEmptySymbolEffect

enum BaseEmptySymbolEffect: Equatable, Sendable {
    case none
    case bounce(BaseEmptySymbolEffectOptions)
    case pulse(BaseEmptySymbolEffectOptions)
    case breathe(BaseEmptySymbolEffectOptions)
    case wiggle(BaseEmptySymbolEffectOptions)
    case rotate(BaseEmptySymbolEffectOptions)
    case scale(BaseEmptySymbolEffectOptions)
    case variableColor(BaseEmptySymbolEffectOptions)

    static let bounce = bounce(.once)
    static let pulse = pulse(.repeating)
    static let breathe = breathe(.repeating)
    static let wiggle = wiggle(.once)
    static let rotate = rotate(.repeating)
    static let scale = scale(.once)
    static let variableColor = variableColor(.byLayerRepeating)
}

// MARK: - BaseEmptyView

@MainActor
class BaseHintView: UIView {

    // MARK: - Types

    enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let imageSize: CGFloat = 48
        static let preferredHeight: CGFloat = 160
        static let defaultImageSystemName = "tray.fill"
    }

    typealias SymbolEffect = BaseEmptySymbolEffect
    typealias Options = BaseEmptySymbolEffectOptions
    typealias LayerMode = BaseEmptySymbolEffectLayerMode

    // MARK: - Properties

    var symbolEffect: SymbolEffect = .bounce {
        didSet {
            guard oldValue != symbolEffect else { return }
            applySymbolEffectIfNeeded()
        }
    }

    // MARK: - UI Elements

    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.secondary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .regular
        )
        imageView.image = UIImage(systemName: Metrics.defaultImageSystemName)
        return imageView
    }()

    private(set) lazy var titleView: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var subtitleView: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            imageView,
            titleView,
            subtitleView,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Metrics.contentSpacing
        return stackView
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
        setAppearance()
        applySymbolEffectIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(
        image: UIImage? = nil,
        title: String? = nil,
        subtitle: String? = nil
    ) {
        applyImage(image)
        titleView.text = title
        titleView.isHidden = title?.isEmpty != false
        subtitleView.text = subtitle
        subtitleView.isHidden = subtitle?.isEmpty != false
    }

    // MARK: - Overridable

    func setHierarchy() {
        addSubview(contentStackView)
    }

    func setLayout() {
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(Metrics.imageSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.greaterThanOrEqualToSuperview().inset(Metrics.verticalInset)
            make.bottom.lessThanOrEqualToSuperview().inset(Metrics.verticalInset)
            make.centerY.equalToSuperview()
        }
    }

    func setAppearance() {
        backgroundColor = .clear
    }

    // MARK: - Private

    private func applyImage(_ image: UIImage?) {
        imageView.image = image ?? UIImage(systemName: Metrics.defaultImageSystemName)
        imageView.isHidden = false
        applySymbolEffectIfNeeded()
    }

    private func applySymbolEffectIfNeeded() {
        imageView.removeAllSymbolEffects()

        switch symbolEffect {
        case .none:
            break

        case .bounce(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(.bounce.wholeSymbol, options: effectOptions)
            case .byLayer:
                imageView.addSymbolEffect(.bounce.byLayer, options: effectOptions)
            }

        case .pulse(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(.pulse.wholeSymbol, options: effectOptions)
            case .byLayer:
                imageView.addSymbolEffect(.pulse.byLayer, options: effectOptions)
            }

        case .breathe(let options):
            let effectOptions = makeSystemOptions(from: options)
            imageView.addSymbolEffect(.breathe, options: effectOptions)

        case .wiggle(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(.wiggle.forward, options: effectOptions)
            case .byLayer:
                imageView.addSymbolEffect(.wiggle.forward.byLayer, options: effectOptions)
            }

        case .rotate(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(.rotate.clockwise, options: effectOptions)
            case .byLayer:
                imageView.addSymbolEffect(.rotate.clockwise.byLayer, options: effectOptions)
            }

        case .scale(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(.scale.up, options: effectOptions)
            case .byLayer:
                imageView.addSymbolEffect(.scale.up.byLayer, options: effectOptions)
            }

        case .variableColor(let options):
            let effectOptions = makeSystemOptions(from: options)
            switch options.layerMode {
            case .wholeSymbol:
                imageView.addSymbolEffect(
                    VariableColorSymbolEffect.variableColor.iterative,
                    options: effectOptions
                )
            case .byLayer:
                imageView.addSymbolEffect(
                    VariableColorSymbolEffect.variableColor.cumulative,
                    options: effectOptions
                )
            }
        }
    }

    private func makeSystemOptions(
        from options: BaseEmptySymbolEffectOptions
    ) -> SymbolEffectOptions {
        let base: SymbolEffectOptions = options.isRepeating ? .repeating : .nonRepeating
        return base.speed(options.speed)
    }
}
