class JiraUserResource < JiraResource
  def picker(email)
    prepare_request
    response = http_get "#{api_url}/user/picker?query=#{email}"
    if response.status == 404
      return nil
    end
    process_response(response, 200) do |response|
      return response.users.first if response.users && response.users.any?
      nil
    end
  end
end
