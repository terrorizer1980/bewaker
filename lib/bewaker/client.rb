module Bewaker

  API_DATA = 'http://localhost:8181/v1/data'
  API_PARTIAL_EVAL = 'http://localhost:8181/v1/compile'

  class Client
    def self.normal_evaluation(input, resource_path)
      HTTParty.post(
        API_DATA + resource_path,
        body: {
          input: input,
        }.to_json,
        headers: get_headers
      )
    end

    def self.partial_evaluation(input, query, unknowns)
      HTTParty.post(
        API_PARTIAL_EVAL,
        body: {
          input: input,
          query: query,
          unknowns: unknowns,
        }.to_json,
        headers: get_headers
      )
    end

    def self.get_headers()
      {
        "Content-Type": "application/json",
      }
    end
  end
end
