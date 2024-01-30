const handleRequest = (args) => {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.request) {
        return window.webkit.messageHandlers.request.postMessage(args).then((result) => {
            console.log(result);
            if (result.error) {
                console.log(result.error);
                return Promise.reject(result.error);
            }
            
            if (result === "null") {
                return Promise.resolve();
            }
            return result;
        });
    }
    return { code: 4900, message: "Host is not ready" }
};

class ReferralBridge {
    static nativeLog(info) {
        handleRequest({ method: "nativeLog", info: info });
    }

    static showShareDialog(link) {
        handleRequest({ method: "showShareDialog", link: link });
    }
    
    static signTransactionAsync() {
        handleRequest({ method: "signTransaction", link: link });
    }

    static getUserPublicKey() {
        handleRequest({ method: "getUserPublicKey", link: link });
    }
}
