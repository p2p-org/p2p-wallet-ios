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
