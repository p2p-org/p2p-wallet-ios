protocol ChooseIndustryDataProvider {
    func getIndustries() -> [Industry]
}

final class ChooseIndustryDataLocalProvider: ChooseIndustryDataProvider {
    func getIndustries() -> [Industry] {
        [
            Industry(emoji: "🧮", title: "Accounting"),
            Industry(emoji: "🔍", title: "Audit"),
            Industry(emoji: "💰", title: "Finance"),
            Industry(emoji: "🏛️", title: "Public sector administration"),
            Industry(emoji: "🎨", title: "Art entertaiment"),
            Industry(emoji: "📐", title: "Auto aviation"),
            Industry(emoji: "💵", title: "Banking lending"),
            Industry(emoji: "⚖️", title: "Business consultancy legal"),
            Industry(emoji: "🧱", title: "Construction repair"),
            Industry(emoji: "📚", title: "Education professional services"),
            Industry(emoji: "🖥", title: "Informational technologies"),
            Industry(emoji: "🍺", title: "Tobacco alcohol"),
            Industry(emoji: "🕹️", title: "Gaming gambling"),
            Industry(emoji: "🌡️", title: "Medical services"),
            Industry(emoji: "🏭", title: "Manufacturing"),
            Industry(emoji: "🎉", title: "PR marketing"),
            Industry(emoji: "💎", title: "Precious goods jewelry"),
            Industry(emoji: "🏢", title: "Non governmental organization"),
            Industry(emoji: "📊", title: "Insurance security v retail wholesale"),
            Industry(emoji: "🏖️", title: "Travel tourism"),
            Industry(emoji: "👾", title: "Freelancer"),
            Industry(emoji: "🎓", title: "Student"),
            Industry(emoji: "🧢", title: "Retired"),
            Industry(emoji: "😜", title: "Unemployed")
        ]
    }
}

