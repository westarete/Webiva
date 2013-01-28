
class JobsList::JobsListTarget < DomainModel

  has_many :jobs_list_jobs_lists

  content_node_type :jobs_list, "JobsList::JobsListPost", :content_name => :name,:title_field => :title, :url_field => :target_permalink

  def content_admin_url(jobs_list_entry_id)
    post = JobsList::JobsListPost.find_by_id(jobs_list_entry_id)
    if post
      {  :controller => '/jobs_list/manage', :action => 'post', :path => [ post.jobs_list_jobs_list_id, jobs_list_entry_id ],
        :title => 'Edit Jobs List Entry'.t}
    else
      {}
    end
  end

  def content_type_name
    "Target Jobs List"
  end

  def name
    self.target_type.to_s.titleize + " Jobs Lists"
  end

  def self.fetch_for_target(target)

    if target.respond_to?(:content_node) && target.content_node
      args = { :content_type_id => target.content_node.content_type_id,
               :target_type => target.class.to_s }
    else
      args = { :target_type => target.class.to_s }
    end
    self.find(:first,:conditions => args) || self.create(args)      
  end

  
end
