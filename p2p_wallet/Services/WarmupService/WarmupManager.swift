// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import Foundation

protocol WarmupProcess {
    func start() async
}

class WarmupManager {
    private var processes: [WarmupProcess]

    init(processes: [WarmupProcess]) {
        self.processes = processes
    }

    func start() async {
        for process in processes {
            await process.start()
        }
    }
}
