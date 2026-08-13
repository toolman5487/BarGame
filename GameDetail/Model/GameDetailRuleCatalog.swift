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
                "在遊戲設定選擇需要的骰子數",
                "搖晃手機擲出骰子",
                "按鎖定固定目前骰子",
                "點確認切換俯視查看結果",
                "返回後開始下一輪"
            )

        case .liarsDice:
            return makeRules(
                "每位玩家準備五顆骰子",
                "各自擲骰並查看自己的結果",
                "起始玩家喊出桌上某個點數的預估總數",
                "下一位玩家必須加碼或質疑上一位玩家",
                "質疑後所有玩家攤開骰子並計算數量",
                "判斷錯誤的一方失去一顆骰子",
                "最後仍持有骰子的玩家獲勝"
            )

        case .mia:
            return makeRules(
                "每位玩家使用兩顆骰子",
                "擲骰後只查看自己的結果",
                "依事前約定的大小順序宣告點數，也可以說謊",
                "下一位玩家選擇接受並繼續，或質疑宣告",
                "質疑後攤開骰子確認結果",
                "說謊被識破或質疑錯誤的一方輸掉本輪"
            )

        case .dicePoker:
            return makeRules(
                "每位玩家使用五顆骰子",
                "所有玩家各自擲骰",
                "完成後同時攤開結果",
                "依單對、兩對、三條、順子、葫蘆與四條比較",
                "組合相同時以組合點數較高者獲勝"
            )

        case .highLow:
            return makeRules(
                "每位玩家使用相同數量的骰子",
                "所有玩家各自擲骰",
                "完成後同時攤開並加總點數",
                "總點數最高者獲勝",
                "最高點數相同時由同分玩家重新擲骰"
            )

        case .oddEven:
            return makeRules(
                "擲骰前先選擇單數或雙數",
                "一次擲出兩顆骰子",
                "將兩顆骰子的點數相加",
                "總點數符合事前選擇的一方獲勝"
            )

        case .sevenElevenDouble:
            return makeRules(
                "開始前約定特殊組合的獎勵或懲罰",
                "每位玩家依序擲出兩顆骰子",
                "總點數為 7、11 或兩顆相同時觸發約定內容",
                "未出現特殊組合時換下一位玩家",
                "完成約定內容後開始下一輪"
            )

        }
    }

    private static func makeRules(_ descriptions: String...) -> [GameDetailRule] {
        descriptions.enumerated().map { index, description in
            GameDetailRule(step: index + 1, text: description)
        }
    }
}
