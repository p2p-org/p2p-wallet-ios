import Foundation

enum RecruitmentBusinessLogic {
    static func sendApplicant(applicantName _: String, apiClient: APIClient) async throws {
        try await apiClient.getData()
    }
}
