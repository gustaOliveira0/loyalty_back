# Parses the last response body as JSON for concise request-spec assertions.
module JsonHelper
  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include JsonHelper, type: :request
end
