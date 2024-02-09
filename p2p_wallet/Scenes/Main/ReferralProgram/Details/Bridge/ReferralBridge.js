const handleRequest = async (args) => {
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
            return {value: result};
        });
    }
    return { code: 4900, message: "Host is not ready" }
};

window.ReferralBridge = {
    getUserPublicKeyAsync: async function() {
        const result = await handleRequest({ method: "getUserPublicKey" });
        ReferralBridge.nativeLog(result);
        return result
    },
    nativeLog: function(info) {
        handleRequest({ method: "nativeLog", info: info });
    },
    showShareDialog: function(link) {
        handleRequest({ method: "showShareDialog", link: link });
    },
    signMessageAsync: async function(message) {
        const result = await handleRequest({ method: "signMessage", message: message });
        return result
    },
    openTermsUrl: function(link) {
        handleRequest({ method: "openTermsUrl", link: link });
    }
}
