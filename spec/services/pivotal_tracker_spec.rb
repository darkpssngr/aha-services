require 'spec_helper'

describe AhaServices::PivotalTracker do
  let(:api_url) { 'https://www.pivotaltracker.com/services/v5' }
  let(:api_token) { 'token' }
  let(:project_id) { '202020' }
  let(:pivot_data) do
    { story_id: '61280364',
      story_url: 'http://www.pivotaltracker.com/story/show/61017898',
      label: {id: '12345678'},
      task_one_id: '18669866' }
  end

  def stub_pivotal_attachment_uploads
    # Upload attachments
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/uploads").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"Austria.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\naaaaaa\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/uploads").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"Belgium.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\nbbbbbb\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/uploads").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"Finland.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\ncccccc\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/uploads").
      with(:body => "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"file\"; filename=\"France.png\"\r\nContent-Length: 6\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\ndddddd\r\n-------------RubyMultipartPost--\r\n\r\n").
      to_return(:status => 200, :body => "", :headers => {})
  end

  describe "receiving new features" do
    let(:service) do
      AhaServices::PivotalTracker.new(
        {'api_token' => api_token, 'project' => project_id, 'api_version' => 'a', 'integration_id' => 111},
        json_fixture('create_feature_event.json'))
    end

    before do
      service.data.stub(:feature_kinds).and_return(Hashie::Mash.new({"54523452345235235" => "New`"}))
      service.data.stub(:mapping).and_return(mapping)


      stub_download_feature_attachments
      stub_pivotal_attachment_uploads

      @create_epic = stub_request(:post, '%s/projects/%s/epics' % [api_url, project_id]).
        to_return(:status => 200, :body => "{\"id\":\"#{pivot_data[:story_id]}\",\"url\":\"#{pivot_data[:story_url]}\",\"label\": {\"id\": \"#{pivot_data[:label][:id]}\"}}", :headers => {})

      @create_story = stub_request(:post, '%s/projects/%s/stories' % [api_url, project_id]).
        to_return(:status => 200, :body => "{\"id\":\"#{pivot_data[:story_id]}\",\"url\":\"#{pivot_data[:story_url]}\"}", :headers => {})

      @create_task = stub_request(:post, '%s/projects/%s/stories/%s/tasks' % [api_url, project_id, pivot_data[:story_id]]).
        to_return(:status => 200, :body => "{\"id\":\"#{pivot_data[:task_one_id]}\"}", :headers => {})

      # Call back into Aha! for requirement
      @integrate_requirement = stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/111/fields").
        with(:body => "{\"integration_fields\":[{\"name\":\"id\",\"value\":\"61280364\"},{\"name\":\"url\",\"value\":\"http://www.pivotaltracker.com/story/show/61017898\"}]}").
        to_return(:status => 201, :body => "", :headers => {})
    end

    context "when the mapping is Feature -> Story, Requirement -> Story" do
      let(:mapping) { "story-story" }

      it "makes certain API calls" do
        # Call back into Aha! for feature
        @integrate_feature = stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/111/fields").
          with(:body => {:integration_fields => [{:name => "id", :value => "#{pivot_data[:story_id]}"}, {:name => "url", :value => "#{pivot_data[:story_url]}"}]}).
          to_return(:status => 201, :body => "", :headers => {})

        # run service
        service.receive(:create_feature)

        # Calling create_story once for the feature and once for the requirement.
        expect(@create_story).to have_been_requested.twice
        expect(@create_task).to_not have_been_requested
        expect(@integrate_feature).to have_been_requested.once
        expect(@integrate_requirement).to have_been_requested.once
      end
    end

    context "when the mapping is Feature -> Epic, Requirement -> Story" do
      let(:mapping) { "epic-story" }

      it "makes certain API calls" do
        @integrate_feature = stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/111/fields").
          with(:body => {:integration_fields => [{:name => "id", :value => "#{pivot_data[:story_id]}"}, {:name => "url", :value => "#{pivot_data[:story_url]}"},{name: "label_id", value: pivot_data[:label][:id]}]}).
          to_return(:status => 201, :body => "", :headers => {})

        # run service
        service.receive(:create_feature)

        expect(@create_epic).to have_been_requested.once
        expect(@create_story).to have_been_requested.once
        expect(@create_task).to_not have_been_requested
        expect(@integrate_feature).to have_been_requested.once
        expect(@integrate_requirement).to have_been_requested.once
      end
    end

    context "when the mapping is Feature -> Story, Requirement -> Task" do
      let(:mapping) { "story-task" }

      it "makes certain API calls" do
        @integrate_feature = stub_request(:post, "https://a.aha.io/api/v1/features/PROD-2/integrations/111/fields").
          with(:body => {:integration_fields => [{:name => "id", :value => "#{pivot_data[:story_id]}"}, {:name => "url", :value => "#{pivot_data[:story_url]}"}]}).
          to_return(:status => 201, :body => "", :headers => {})

        @integrate_requirement = stub_request(:post, "https://a.aha.io/api/v1/requirements/PROD-2-1/integrations/111/fields").
          with(:body => "{\"integration_fields\":[{\"name\":\"id\",\"value\":\"18669866\"},{\"name\":\"url\",\"value\":\"http://www.pivotaltracker.com/story/show/61017898\"}]}").
          to_return(:status => 201, :body => "", :headers => {})

        # run service
        service.receive(:create_feature)

        expect(@create_epic).to_not have_been_requested
        expect(@create_story).to have_been_requested.once
        expect(@create_task).to have_been_requested.once
        expect(@integrate_feature).to have_been_requested.once
        expect(@integrate_requirement).to have_been_requested.once
      end
    end
  end

  it "can update existing features" do
    stub_download_feature_attachments
    stub_pivotal_attachment_uploads

    # Call to PivotalTracker
    stub_request(:put, 'https://www.pivotaltracker.com/services/v5/projects/202020/stories/18669866').
      to_return(:status => 200, :body => "{}", :headers => {})
    stub_request(:put, 'https://www.pivotaltracker.com/services/v5/projects/202020/stories/61280364').
      to_return(:status => 200, :body => "{}", :headers => {})
    stub_request(:get, "https://www.pivotaltracker.com/services/v5/projects/202020/stories/61280364/comments?fields=file_attachments").
      to_return(:status => 200, :body => "{}", :headers => [])
    stub_request(:get, "https://www.pivotaltracker.com/services/v5/projects/202020/stories/18669866/comments?fields=file_attachments").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/stories/18669866/comments").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:post, "https://www.pivotaltracker.com/services/v5/projects/202020/stories/61280364/comments").
      to_return(:status => 200, :body => "", :headers => {})
    AhaServices::PivotalTracker.new(
      {'api_token' => api_token, 'project' => project_id, 'api_version' => 'a'},
      json_fixture('update_feature_event.json')).receive(:update_feature)
  end

  it "raises error when PivotalTracker fails" do
    stub_download_feature_attachments
    stub_pivotal_attachment_uploads

    stub_request(:post, '%s/projects/%s/stories' % [api_url, project_id]).
      to_return(:status => 401, :body => raw_fixture('pivotal_tracker/invalid_parameter.json'), :headers => {})
    expect {
      AhaServices::PivotalTracker.new(
        {'api_token' => api_token, 'project' => project_id, 'api_version' => 'a', 'feature_kinds' => {"54523452345235235" => "New"}},
        json_fixture('create_feature_event.json')).receive(:create_feature)
    }.to raise_error(AhaService::RemoteError)
  end

  it "raises authentication error" do
    stub_download_feature_attachments
    stub_pivotal_attachment_uploads

    stub_request(:post, '%s/projects/%s/stories' % [api_url, project_id]).
      to_return(:status => 401, :body => raw_fixture('pivotal_tracker/auth_error.json'), :headers => {})

    expect {
      # run service
      AhaServices::PivotalTracker.new(
        {'api_token' => '', 'project' => project_id, 'api_version' => 'a', 'feature_kinds' => {"54523452345235235" => "New"}},
        json_fixture('create_feature_event.json')).receive(:create_feature)
    }.to raise_error(AhaService::RemoteError)
  end

  context "can be installed" do

    it "handles installed event" do

      stub_request(:get, '%s/projects' % [api_url]).
        to_return(:status => 200, :body => raw_fixture('pivotal_tracker/projects.json'), :headers => {})
      stub_request(:get, "https://www.pivotaltracker.com/services/v5/projects/98/integrations").
        to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "https://www.pivotaltracker.com/services/v5/projects/99/integrations").
        to_return(:status => 200, :body => "", :headers => {})

      service = AhaServices::PivotalTracker.new(
        {'api_token' => api_token, 'api_version' => 'a', 'integration_id' => 111, 'feature_kinds' => {"54523452345235235" => "New"}},
        nil)
      service.receive(:installed)
      service.meta_data.projects[0]["name"].should == "Learn About the Force"
      service.meta_data.projects[0]["id"].should == 98
    end

  end

end
