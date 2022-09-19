struct PincodeSnackbar {
    let title: String?
    let message: String
    let isFailure: Bool

    init(title: String? = nil, message: String, isFailure: Bool) {
        self.title = title
        self.message = message
        self.isFailure = isFailure
    }
}
