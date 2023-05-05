# Copyright 2022 P2P Validator Authors. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.

swift package --allow-writing-to-directory ./docs \
    generate-documentation --target TransactionParser \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path "solana-swift-library" \
    --output-path ./docs