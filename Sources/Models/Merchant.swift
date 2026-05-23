import Foundation

struct Merchant: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var category: String?
    var hasWithdrawalButton: Bool
    var withdrawalButtonURL: URL?
    var legalEmail: String?
    var difficultyScore: Int?

    init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        hasWithdrawalButton: Bool = false,
        withdrawalButtonURL: URL? = nil,
        legalEmail: String? = nil,
        difficultyScore: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.hasWithdrawalButton = hasWithdrawalButton
        self.withdrawalButtonURL = withdrawalButtonURL
        self.legalEmail = legalEmail
        self.difficultyScore = difficultyScore
    }
}
