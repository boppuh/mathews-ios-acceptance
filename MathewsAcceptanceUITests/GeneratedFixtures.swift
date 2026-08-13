import Foundation

enum GeneratedFixtures {
  static func data(named name: String) throws -> Data {
    let encoded = switch name {
    case "primary.json":
      "ewogICJmaXh0dXJlX2lkIjogInByaW1hcnlfZml4dHVyZSIsCiAgImZpeHR1cmVfdmVyc2lvbiI6IDEsCiAgInNjaGVtYV92ZXJzaW9uIjogMSwKICAidmFsdWVzIjogewogICAgInRhc2sudGl0bGUiOiAiUHJlcGFyZSBNVlAgcmVsZWFzZSIKICB9Cn0K"
    case "primary-account.json":
      "ewogICJjcmVkZW50aWFsX3NvdXJjZSI6ICJPUEFRVUVfU0VDUkVUX1JFRkVSRU5DRSIsCiAgInJlY2lwZV9pZCI6ICJwcmltYXJ5X2FjY291bnQiLAogICJyZWNpcGVfdmVyc2lvbiI6IDEsCiAgInNjaGVtYV92ZXJzaW9uIjogMQp9Cg=="
    default:
      throw GeneratedFixtureError.unknownFixture
    }
    guard let data = Data(base64Encoded: encoded) else {
      throw GeneratedFixtureError.invalidEncoding
    }
    return data
  }
}

private enum GeneratedFixtureError: Error {
  case invalidEncoding
  case unknownFixture
}
