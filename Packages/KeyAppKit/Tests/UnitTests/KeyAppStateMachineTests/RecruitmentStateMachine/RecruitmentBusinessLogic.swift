import Foundation

enum RecruitmentBusinessLogic {
    static func sendApplicant(applicantName: String, apiClient: APIClient) async throws {
        try await apiClient.getData()
    }
}
