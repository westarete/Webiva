require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::AdminController do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types

  it "should be able to create a jobs list" do
    mock_editor

    assert_difference 'JobsList::JobsListJobsList.count', 1 do
      post 'create', :path => [], :jobs_list => { :name => 'Test Jobs List', :content_filter => 'full_html' }
      @jobs_list = JobsList::JobsListJobsList.find(:last)
      response.should redirect_to(:controller => '/jobs_list/manage', :path => [@jobs_list.id])
    end
  end

end
