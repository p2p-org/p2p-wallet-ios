public struct TipContent {
    let currentNumber: Int
    let count: Int
    let text: String
    let nextButtonText: String
    let skipButtonText: String

    public init(currentNumber: Int, count: Int, text: String, nextButtonText: String, skipButtonText: String) {
        self.currentNumber = currentNumber
        self.count = count
        self.text = text
        self.nextButtonText = nextButtonText
        self.skipButtonText = skipButtonText
    }
}
