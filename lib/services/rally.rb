class AhaServices::Rally < AhaService
  caption "Send releases, features and requirements to Rally"

  string :user_name, description: "The name of the user used to access Rally."
  password :user_password, description: "The password of the user."

  install_button

  select :project, description: "The Rally project that this Aha! product will integrate with.", collection: -> (meta_data,data) {
    meta_data.projects.collect {|p| [p.Name, p.ObjectID] }
  }

  def receive_installed
    projects = rally_project_resource.all
    meta_data.projects = projects
  end

  def receive_create_release
    rally_release_resource.create payload.release
  end

  def receive_update_release
    rally_release_resource.update payload.release
  end

protected
  def rally_resource
    @rally_resource ||= RallyResource.new self
  end

  def rally_release_resource
    @rally_release_resource ||= RallyReleaseResource.new self
  end

  def rally_project_resource
    @rally_project_resource ||= RallyProjectResource.new self
  end
end
