import BankTransfer

final class ChooseIndustryDataLocalProvider {
    private let emojis: [StrigaUserIndustry: String] = [
        .accounting: "🧮",
        .audit: "🔍",
        .finance: "💰",
        .publicSectorAdministration: "🏛️",
        .artEntertaiment: "🎨",
        .autoAviation: "📐",
        .bankingLending: "💵",
        .businessConsultancyLegal: "⚖️",
        .constructionRepair: "🧱",
        .educationProfessionalServices: "📚",
        .informationalTechnologies: "🖥",
        .tobaccoAlcohol: "🍺",
        .gamingGambling: "🕹️",
        .medicalServices: "🌡️",
        .manufacturing: "🏭",
        .prMarketing: "🎉",
        .preciousGoodsJewelry: "💎",
        .nonGovernmentalOrganization: "🏢",
        .insuranceSecurityVRetailWholesale: "📊",
        .travelTourism: "🏖️",
        .freelancer: "👾",
        .student: "🎓",
        .retired: "🧢",
        .unemployed: "😜"
    ]

    func getIndustries() -> [Industry] {
        StrigaUserIndustry.allCases.map { industry in
            return Industry(emoji: emojis[industry] ?? "", title: industry.rawValue.formatted(), rawValue: industry)
        }
    }
}

private extension String {
    func formatted() -> String {
        return self.replacingOccurrences(of: "_", with: " ").lowercased().uppercaseFirst
    }
}

