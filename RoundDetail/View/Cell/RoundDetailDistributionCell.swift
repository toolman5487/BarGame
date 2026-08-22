//
//  RoundDetailDistributionCell.swift
//  BarGame
//
//  Created by Codex on 2026/8/22.
//

import Charts
import SnapKit
import SwiftUI
import UIKit

@MainActor
final class RoundDetailDistributionCell: DetailBaseCollectionViewCell {

    enum Metrics {
        static let preferredHeight: CGFloat = 208
        static let verticalCardInset: CGFloat = 4
    }

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

    func configure(items: [RoundDetailDistributionItem]) {
        contentConfiguration = UIHostingConfiguration {
            RoundDetailDistributionChart(items: items)
        }
        .margins(.all, 0)
        .background(.clear)
    }
}

private struct RoundDetailDistributionChart: View {

    private enum Metrics {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let contentSpacing: CGFloat = 8
    }

    let items: [RoundDetailDistributionItem]

    private var totalDiceCount: Int {
        items.reduce(into: 0) { total, item in
            total += item.count
        }
    }

    private var maximumCount: Int {
        max(items.map(\.count).max() ?? 0, 1)
    }

    private var yAxisValues: [Int] {
        Array(Set([0, maximumCount / 2, maximumCount])).sorted()
    }

    private var yDomain: ClosedRange<Double> {
        0...Double(maximumCount + 1)
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
            Text("骰子數量")
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            Spacer(minLength: 8)
            Text("\(totalDiceCount) 顆")
                .fontWeight(.semibold)
                .foregroundStyle(Color(uiColor: ThemeColor.primary))
        }
        .font(.caption)
        .monospacedDigit()
    }

    private var chart: some View {
        Chart(items) { item in
            BarMark(
                x: .value("點數", item.faceValue),
                y: .value("顆數", item.count),
                width: .ratio(0.55)
            )
            .foregroundStyle(
                item.count > 0
                    ? Color.yellow
                    : Color(uiColor: ThemeColor.secondary).opacity(0.15)
            )
            .annotation(position: .top) {
                if item.count > 0 {
                    Text(String(item.count))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Color(uiColor: ThemeColor.primary))
                }
            }
        }
        .chartXScale(domain: 0.5...6.5)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: items.map(\.faceValue)) { value in
                AxisValueLabel {
                    if let faceValue = value.as(Int.self) {
                        Image(systemName: "die.face.\(faceValue).fill")
                    }
                }
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine()
                    .foregroundStyle(
                        Color(uiColor: ThemeColor.secondary).opacity(0.15)
                    )
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text(String(count))
                    }
                }
                .foregroundStyle(Color(uiColor: ThemeColor.secondary))
            }
        }
    }
}
