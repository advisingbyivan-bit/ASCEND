import Foundation

public enum RewardDispatcher {
    /// Variable reward split: 70% standard, 20% bonus, 10% mega (only on milestone days)
    public static func evaluate(streak: Int, milestone: DiamondMilestone?) -> ScanReward {
        if let milestone {
            return .mega(milestone)
        }

        let roll = Double.random(in: 0...1)
        if roll < 0.7 {
            return .standard
        } else {
            return .bonus
        }
    }
}
