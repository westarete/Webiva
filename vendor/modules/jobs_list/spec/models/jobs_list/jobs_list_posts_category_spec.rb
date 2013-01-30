require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::JobsListPostsCategory do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types

  it "should be able to set jobs list post categories" do
    @jobs_list = JobsList::JobsListJobsList.create :name => 'Test Jobs List', :content_filter => 'full_html'
    @category = @jobs_list.jobs_list_categories.create :name => 'Test Category'
    @post = @jobs_list.jobs_list_posts.new :title => 'Test Post', :body => 'Testerama',:job_status => 'Anonymous'
    @post.save

    assert_difference 'JobsList::JobsListPostsCategory.count', 1 do
      @post.set_categories! [@category.id]
    end

    @post_category = JobsList::JobsListPostsCategory.find_by_jobs_list_post_id_and_jobs_list_category_id @post.id, @category.id
    @post_category.should_not be_nil
  end

end
