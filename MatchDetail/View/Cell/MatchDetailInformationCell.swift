//
//  MatchDetailInformationCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import CoreLocation
import MapKit
import SnapKit
import UIKit

@MainActor
final class MatchDetailInformationCell: DetailBaseCollectionViewCell {

    var retryHandler: (() -> Void)?

    enum Metrics {
        static let preferredHeight: CGFloat = 280
        static let verticalInset: CGFloat = 4
        static let textHorizontalInset: CGFloat = 16
        static let mapHeight: CGFloat = 176
        static let mapCornerRadius: CGFloat = 16
        static let mapTextSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        static let regionDistance: CLLocationDistance = 800
    }

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
        mapView.layer.cornerRadius = Metrics.mapCornerRadius
        mapView.layer.masksToBounds = true
        return mapView
    }()

    private let placeholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Metrics.mapCornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.secondary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            textStyle: .title2
        )
        return imageView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var placeholderStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            activityIndicator,
            placeholderImageView,
            placeholderLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private let areaLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = ThemeColor.primary
        label.numberOfLines = 1
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let startedAtLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.secondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            areaLabel,
            addressLabel,
            startedAtLabel,
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Metrics.textSpacing
        return stackView
    }()

    // MARK: - Overridable

    override func setHierarchy() {
        mapView.delegate = self
        contentView.addSubview(mapView)
        contentView.addSubview(placeholderView)
        placeholderView.addSubview(placeholderStackView)
        contentView.addSubview(textStackView)
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleRetryTap)
        )
        placeholderView.addGestureRecognizer(tapGesture)
    }

    override func setLayout() {
        mapView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(Metrics.verticalInset)
            make.height.equalTo(Metrics.mapHeight)
        }

        placeholderView.snp.makeConstraints { make in
            make.edges.equalTo(mapView)
        }

        placeholderStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
                .inset(Metrics.textHorizontalInset)
        }

        textStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
                .inset(Metrics.textHorizontalInset)
            make.top.equalTo(mapView.snp.bottom)
                .offset(Metrics.mapTextSpacing)
            make.bottom.lessThanOrEqualToSuperview()
                .inset(Metrics.verticalInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mapView.removeAnnotations(mapView.annotations)
        areaLabel.text = nil
        addressLabel.text = nil
        startedAtLabel.text = nil
        retryHandler = nil
        showLoadingState()
    }

    // MARK: - Configuration

    func configure(information: MatchDetailInformation) {
        areaLabel.text = information.areaText
        addressLabel.text = information.detailAddressText
        startedAtLabel.text = "開始時間 \(information.startedAtText)"

        switch information.mapState {
        case .located(let coordinate):
            showMap(
                coordinate: coordinate,
                annotationTitle: information.areaText
            )

        case .notRecorded:
            showNotRecordedState()
        }
    }

    // MARK: - Private

    private func showLoadingState() {
        mapView.isHidden = true
        placeholderView.isHidden = false
        placeholderView.isUserInteractionEnabled = false
        placeholderImageView.isHidden = true
        placeholderLabel.text = "正在載入地圖"
        activityIndicator.startAnimating()
    }

    private func showUnavailableState() {
        mapView.isHidden = true
        placeholderView.isHidden = false
        placeholderView.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
        placeholderImageView.isHidden = false
        placeholderImageView.image = UIImage(systemName: "map")
        placeholderLabel.text = "目前無法顯示這個地點\n輕觸重試"
    }

    private func showNotRecordedState() {
        mapView.isHidden = true
        placeholderView.isHidden = false
        placeholderView.isUserInteractionEnabled = false
        activityIndicator.stopAnimating()
        placeholderImageView.isHidden = false
        placeholderImageView.image = UIImage(systemName: "mappin.slash")
        placeholderLabel.text = "這場賽局未記錄地點"
    }

    private func showMap(
        coordinate: GameCoordinate,
        annotationTitle: String
    ) {
        let mapCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        guard CLLocationCoordinate2DIsValid(mapCoordinate) else {
            showUnavailableState()
            return
        }

        activityIndicator.stopAnimating()
        placeholderView.isHidden = true
        placeholderView.isUserInteractionEnabled = false
        mapView.isHidden = false
        mapView.removeAnnotations(mapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = mapCoordinate
        annotation.title = annotationTitle
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(
            center: mapCoordinate,
            latitudinalMeters: Metrics.regionDistance,
            longitudinalMeters: Metrics.regionDistance
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: false)
    }

    @objc
    private func handleRetryTap() {
        retryHandler?()
    }
}

// MARK: - MKMapViewDelegate

extension MatchDetailInformationCell: MKMapViewDelegate {

    func mapViewDidFailLoadingMap(
        _ mapView: MKMapView,
        withError error: any Error
    ) {
        showUnavailableState()
    }
}
