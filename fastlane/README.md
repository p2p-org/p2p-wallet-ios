fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Setup

Add `.env` file contains following content (ask teamate):
```
DEVELOPER_APP_IDENTIFIER="org.p2p.cyber"
APP_STORE_CONNECT_TEAM_ID="123992888"
DEVELOPER_PORTAL_TEAM_ID="A72KN37UN2"
DEVELOPER_APP_ID="1605603333"
PROVISIONING_PROFILE_SPECIFIER="match AppStore org.p2p.cyber"
APPLE_ISSUER_ID="18c42961-aa9a-42fe-923c-9790a4ae2982"

PROVISIONING_REPO="git@github.com:p2p-org/certificates.git"

FIREBASE_APP_ID="<app_id>"
FIREBASE_CLI_TOKEN="<cli_token>"

BROWSERSTACK_USERNAME="<username>"
BROWSERSTACK_ACCESS_KEY="<access_key>"

FASTLANE_APPLE_ID="example@email.com"
TEMP_KEYCHAIN_USER=""
TEMP_KEYCHAIN_PASSWORD=""
APPLE_KEY_ID=""
APPLE_KEY_CONTENT="-----BEGIN PRIVATE KEY-----
<KEY>
-----END PRIVATE KEY-----"
GIT_AUTHORIZATION="<username>:<github_personal_private_token>"

```

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```



### ios closed_beta

```sh
[bundle exec] fastlane ios closed_beta
```



----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
