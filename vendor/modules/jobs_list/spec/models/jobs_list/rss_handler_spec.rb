require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::RssHandler do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
    @category = @jobs_list.jobs_list_categories.create :name => 'new'
    @post = @jobs_list.jobs_list_posts.new  :title => 'Test Post', :body => 'Test Body'
    @post.publish 5.minutes.ago
    @post.save
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    @rss_page_node = SiteVersion.default.root.add_subpage('rss')
    @options = JobsList::RssHandler::Options.new :feed_identifier => "#{@rss_page_node.id},#{@jobs_list.id},#{@detail_page_node.id}", :limit => 10
  end
  
  it "should create the data for an rss feed" do
    @feed = JobsList::RssHandler.new(@options)
    data = @feed.get_feed
    data[:title].should == 'Test Jobs List'
    data[:items][0][:title].should == 'Test Post'
  end
end
