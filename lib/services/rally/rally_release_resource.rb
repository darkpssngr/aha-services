class RallyReleaseResource < RallyResource
  def by_id id
    url = rally_url "/release/#{id}"
    response = http_get url
    process_response response do |document|
      return document.Release
    end
  end

  def create aha_release
    get_security_token
    body = { :Release => map_release(aha_release) }.to_json
    url = rally_secure_url "/release/create"
    response = http_put url, body
    process_response response, 200, 201 do |document|
      rally_release = document.CreateResult.Object
      api.create_integration_fields "releases", aha_release.id, @service.data.integration_id, { id: rally_release.ObjectID, url: rally_release._ref }
    end
  end

  def update aha_release
    get_security_token
    id = aha_release.integration_fields.find{|field| field.integration_id == @service.data.integration_id.to_s and field.name == "id"}.value
    body = { :Release =>  map_release(aha_release) }.to_json
    url = rally_secure_url "/release/#{id}"
    response = http_post url, body
    process_response response
  end

protected
  def map_release aha_release
    release = {
      :Name => aha_release.name,
      :Project => @service.data.project,
      :ReleaseDate => aha_release.release_date,
      :ReleaseStartDate => aha_release.created_at,
      :State => "Planning",
      :Theme => aha_release.theme.body
    }
  end
end
