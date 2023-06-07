import BankTransfer

final class ChooseIndustryDataLocalProvider {
    private let emojis: [StrigaUserIndustry: String] = [
        .accounting: "🧮",
        .selfEmployed: "",
        .audit: "🔍",
        .finance: "💰",
        .publicSectorAdministration: "🏛️",
        .artEntertainment: "🎨",
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
        .insuranceSecurity: "📊",
        .retailWholesale: "📊",
        .travelTourism: "🏖️",
        .freelancer: "👾",
        .student: "🎓",
        .retired: "🧢",
        .unemployed: "😜",
        .other: ""
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

