//
//  MainHomeLocationMapCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/16.
//

import CoreLocation
import MapKit
import SnapKit
import UIKit

@MainActor
final class MainHomeLocationMapCell: MainBaseCollectionViewCell {

    // MARK: - Metrics

    enum Metrics {
        static let preferredHeight: CGFloat = 216
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let cornerRadius: CGFloat = 16
        static let textInset: CGFloat = 12
        static let minimumRegionDistance: CLLocationDistance = 600
        static let maximumRegionDistance: CLLocationDistance = 3_000
    }

    // MARK: - State

    private var displayedCoordinate: GameCoordinate?

    // MARK: - UI Elements

    private let mapView: MKMapView = {
        let mapView = MKMapView()
        let configuration = MKStandardMapConfiguration()
        configuration.elevationStyle = .flat
        configuration.emphasisStyle = .muted
        mapView.preferredConfiguration = configuration
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isUserInteractionEnabled = false
        mapView.layer.cornerRadius = Metrics.cornerRadius
        mapView.layer.masksToBounds = true
        return mapView
    }()

    private let placeholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Metrics.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title1
        )
        imageView.tintColor = ThemeColor.secondary
        return imageView
    }()

    private let placeholderTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let placeholderSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var placeholderStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            placeholderImageView,
            placeholderTitleLabel,
            placeholderSubtitleLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        contentView.addSubview(mapView)
        contentView.addSubview(placeholderView)
        placeholderView.addSubview(placeholderStackView)
    }

    override func setLayout() {
        mapView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Metrics.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Metrics.verticalInset)
        }

        placeholderView.snp.makeConstraints { make in
            make.edges.equalTo(mapView)
        }

        placeholderStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview().inset(Metrics.textInset)
        }
    }

    override func setAppearance() {
        super.setAppearance()
        contentView.backgroundColor = .systemBackground
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        displayedCoordinate = nil
        mapView.removeAnnotations(mapView.annotations)
        showPlaceholder(
            systemName: "location",
            title: "準備取得位置",
            subtitle: "正在確認目前位置"
        )
    }

    // MARK: - Configuration

    func configure(state: MainHomeLocationState) {
        switch state {
        case .idle:
            showPlaceholder(
                systemName: "location",
                title: "準備取得位置",
                subtitle: "正在確認目前位置"
            )

        case .refreshing(.none):
            showPlaceholder(
                systemName: "location.fill.viewfinder",
                title: "正在取得位置",
                subtitle: "完成後會在地圖上標示目前位置"
            )

        case .refreshing(.some(let item)):
            showMap(item: item)

        case .located(let item):
            showMap(item: item)

        case .failed(.none):
            showPlaceholder(
                systemName: "location.slash.fill",
                title: "無法取得目前位置",
                subtitle: "請使用右上角定位按鈕重新取得"
            )

        case .failed(.some(let item)):
            showMap(item: item)
        }
    }

    // MARK: - Private

    private func showMap(item: MainHomeLocationItem) {
        let coordinate = CLLocationCoordinate2D(
            latitude: item.coordinate.latitude,
            longitude: item.coordinate.longitude
        )
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            showPlaceholder(
                systemName: "location.slash.fill",
                title: "位置資料異常",
                subtitle: "請重新取得目前位置"
            )
            return
        }

        placeholderView.isHidden = true
        mapView.isHidden = false

        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)

        let distance = min(
            max(
                item.horizontalAccuracy * 4,
                Metrics.minimumRegionDistance
            ),
            Metrics.maximumRegionDistance
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance
        )
        mapView.setRegion(
            mapView.regionThatFits(region),
            animated: displayedCoordinate != nil
                && displayedCoordinate != item.coordinate
        )
        displayedCoordinate = item.coordinate
    }

    private func showPlaceholder(
        systemName: String,
        title: String,
        subtitle: String
    ) {
        mapView.isHidden = true
        placeholderView.isHidden = false
        placeholderImageView.image = UIImage(systemName: systemName)
        placeholderTitleLabel.text = title
        placeholderSubtitleLabel.text = subtitle
    }
}
