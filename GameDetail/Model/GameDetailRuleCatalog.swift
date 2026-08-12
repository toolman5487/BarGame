//
//  GameDetailRuleCatalog.swift
//  BarGame
//
//  Created by Willy Hsu on 2026/8/12.
//

import Foundation

nonisolated enum GameDetailRuleCatalog {

    static func rules(for gameID: DiceGameID) -> [GameDetailRule] {
        switch gameID {
        case .dice:
            return makeRules(
                "點加號加入需要的骰子",
                "搖晃手機擲出骰子",
                "按鎖定固定目前骰子",
                "點確認切換俯視查看結果",
                "返回後開始下一輪"
            )

        case .playingCards:
            return makeRules(
                "決定牌組與參與玩家",
                "洗牌後由每位玩家依序抽牌",
                "依選定玩法比較牌面或執行指令",
                "收回所有牌後重新洗牌"
            )

        case .roulette:
            return makeRules(
                "加入玩家、挑戰或獎勵",
                "選定本輪轉動輪盤的玩家",
                "轉動輪盤並等待指針停止",
                "指針所指即為本輪結果",
                "完成指定內容後開始下一輪"
            )

        case .sicBo:
            return makeRules(
                "每位玩家選擇要預測的骰寶項目",
                "一次擲出三顆骰子",
                "總點數 4 至 10 為小",
                "總點數 11 至 17 為大",
                "三顆相同為圍骰",
                "圍骰時大小預測皆失敗",
                "依點數或組合判定結果"
            )

        case .blackjack:
            return makeRules(
                "目標是不超過 21 點",
                "點數越接近 21 點越好",
                "玩家與莊家起手各取得兩張牌",
                "A 可算 1 或 11 點",
                "J、Q、K 各算 10 點",
                "玩家可選擇要牌或停牌",
                "超過 21 點即爆牌",
                "莊家未滿 17 點必須要牌",
                "最後與莊家比較點數"
            )

        case .bingo:
            return makeRules(
                "每位玩家取得一張賓果卡",
                "主持人隨機抽出並公布號碼",
                "出現相同號碼時標記該格",
                "率先完成指定連線者喊賓果",
                "確認連線無誤後獲勝"
            )
        }
    }

    private static func makeRules(_ descriptions: String...) -> [GameDetailRule] {
        descriptions.enumerated().map { index, description in
            GameDetailRule(step: index + 1, text: description)
        }
    }
}
