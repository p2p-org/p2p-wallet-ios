import LinkPresentation

class SentViaLinkActivityItemSource: NSObject, UIActivityItemSource {
    let title: String = L10n.keyAppOneTimeTransferLink
    let sender: String
    let amount: Double
    let symbol: String
    let url: URL
    
    init(
        sender: String,
        amount: Double,
        symbol: String,
        url: URL
    ) {
        self.sender = sender
        self.amount = amount
        self.symbol = symbol
        self.url = url
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        title
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        L10n.heyIVeSentYouGetItHere(amount.toString(maximumFractionDigits: 9), symbol, url.absoluteString)
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        title
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.iconProvider = NSItemProvider(object: UIImage.appIconSquare)
        metadata.imageProvider = nil
        //This is a bit ugly, though I could not find other ways to show text content below title.
        //https://stackoverflow.com/questions/60563773/ios-13-share-sheet-changing-subtitle-item-description
        //You may need to escape some special characters like "/".
//        metadata.originalURL = url
        return metadata
    }
    
}
