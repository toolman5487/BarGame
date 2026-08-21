//
//  MatchDetailProgressionCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/21.
//

import Charts
import SnapKit
import SwiftUI
import UIKit

@MainActor
final class MatchDetailProgressionCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 176
        static let verticalCardInset: CGFloat = 4
    }

    // MARK: - UI Elements

    private let backgroundButton = ViewFactory.makeButton()

    override func setHierarchy() {
        contentView.addSubview(backgroundButton)
    }

    override func setLayout() {
        backgroundButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Metrics.verticalCardInset)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
    }

    func configure(items: [MatchDetailProgressionItem]) {
        contentConfiguration = UIHostingConfiguration {
            MatchDetailProgressionChart(items: items)
        }
        .margins(.all, 0)
        .background(.clear)
    }
}

private struct MatchDetailProgressionChart: View {

    private enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let contentSpacing: CGFloat = 8
        static let lineWidth: CGFloat = 2
        static let pointSize: CGFloat = 8
        static let lossPointSize: CGFloat = 7
    }

    let items: [MatchDetailProgressionItem]

    private var yAxisValues: [Int] {
        let values = items.map(\.cumulativeDifference)
        let minimum = min(values.min() ?? 0, 0)
        let maximum = max(values.max() ?? 0, 0)
        return Array(Set([minimum, 0, maximum])).sorted()
    }

    private var yDomain: ClosedRange<Int> {
        let lowerBound = (yAxisValues.first ?? 0) - 1
        let upperBound = (yAxisValues.last ?? 0) + 1
        return lowerBound...upperBound
    }

    private var xDomain: ClosedRange<Double> {
        guard let firstSequence = items.first?.sequence,
              let lastSequence = items.last?.sequence else {
            return 0...1
        }
        return (Double(firstSequence) - 0.4)...(Double(lastSequence) + 0.4)
    }

    private var xAxisValues: [Int] {
        guard items.count > 6 else {
            return items.map(\.sequence)
        }

        let lastIndex = items.index(before: items.endIndex)
        let interval = max(1, Int(ceil(Double(lastIndex) / 4)))
        var values = stride(
            from: items.startIndex,
            through: lastIndex,
            by: interval
        )
            .map { items[$0].sequence }

        if values.last != items[lastIndex].sequence {
            values.append(items[lastIndex].sequence)
        }
        return values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
            summary
            chart
        }
        .padding(.horizontal, Metrics.horizontalInset)
        .padding(.vertical, Metrics.verticalInset)
    }

    private var summary: some View {
        HStack(spacing: 4) {
            Text("淨勝差")
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            Spacer(minLength: 8)
            Text(items.last?.cumulativeDifferenceText ?? "0")
                .fontWeight(.semibold)
                .foregroundStyle(Color(uiColor: ThemeColor.primary))
        }
        .font(.caption)
        .monospacedDigit()
    }

    private var chart: some View {
        Chart {
            RuleMark(y: .value("基準", 0))
                .foregroundStyle(Color(uiColor: ThemeColor.secondary).opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            ForEach(items) { item in
                LineMark(
                    x: .value("回合", item.sequence),
                    y: .value("累積淨勝差", item.cumulativeDifference)
                )
                .foregroundStyle(Color(uiColor: ThemeColor.primary))
                .lineStyle(
                    StrokeStyle(
                        lineWidth: Metrics.lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

                PointMark(
                    x: .value("回合", item.sequence),
                    y: .value("累積淨勝差", item.cumulativeDifference)
                )
                .symbol {
                    pointSymbol(for: item.outcome)
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXScale(domain: xDomain)
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisValueLabel {
                    if let sequence = value.as(Int.self) {
                        Text(String(sequence))
                    }
                }
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisValueLabel {
                    if let difference = value.as(Int.self) {
                        Text(difference > 0 ? "+\(difference)" : String(difference))
                    }
                }
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            }
        }
    }

    @ViewBuilder
    private func pointSymbol(for outcome: RoundOutcome) -> some View {
        switch outcome {
        case .win:
            Circle()
                .fill(Color.yellow)
                .frame(width: Metrics.pointSize, height: Metrics.pointSize)

        case .loss:
            Rectangle()
                .fill(Color(uiColor: ThemeColor.primary))
                .frame(width: Metrics.lossPointSize, height: Metrics.lossPointSize)
                .rotationEffect(.degrees(45))
        }
    }
}
