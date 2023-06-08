import BankTransfer

final class ChooseIndustryDataLocalProvider {
    
    private func getEmoji(industry: StrigaUserIndustry) -> String {
        switch industry {
        case .accounting: return "🧮"
        case .selfEmployed: return "😎"
        case .audit: return "🔍"
        case .finance: return "💰"
        case .publicSectorAdministration: return "🏛️"
        case .artEntertainment: return "🎨"
        case .autoAviation: return "📐"
        case .bankingLending: return "💵"
        case .businessConsultancyLegal: return "⚖️"
        case .constructionRepair: return "🧱"
        case .educationProfessionalServices: return "📚"
        case .informationalTechnologies: return "🖥"
        case .tobaccoAlcohol: return "🍺"
        case .gamingGambling: return "🕹️"
        case .medicalServices: return "🌡️"
        case .manufacturing: return "🏭"
        case .prMarketing: return "🎉"
        case .preciousGoodsJewelry: return "💎"
        case .nonGovernmentalOrganization: return "🏢"
        case .insuranceSecurity: return "📊"
        case .retailWholesale: return "🛍️"
        case .travelTourism: return "🏖️"
        case .freelancer: return "👾"
        case .student: return "🎓"
        case .retired: return "🧢"
        case .unemployed: return "😜"
        }
    }

    func getIndustries() -> [Industry] {
        StrigaUserIndustry.allCases.map { industry in
            return Industry(emoji: getEmoji(industry: industry), title: industry.rawValue.formatted(), rawValue: industry)
        }
    }
}

private extension String {
    func formatted() -> String {
        return self.replacingOccurrences(of: "_", with: " ").lowercased().uppercaseFirst
    }
}

