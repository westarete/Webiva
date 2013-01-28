require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe JobsList::EditRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/jobs_list/edit/' + paragraph, options, inputs)
  end

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html', :is_user_jobs_list => true)
    @category = @jobs_list.jobs_list_categories.create :name => 'new'
    @post = @jobs_list.jobs_list_posts.new :title => 'Test Post', :body => 'Test Body'
    @post.publish 5.minutes.ago
    @post.save
    @jobs_list.target = @post
    @jobs_list.save

    @edit_page_node = SiteVersion.default.root.add_subpage('edit')
    @list_page_node = SiteVersion.default.root.add_subpage('list')
  end

  it "should be able to list user posts" do
    inputs = { :input => [:container, @post] }
    options = {:auto_create => true, :jobs_list_name => '%s Jobs List',:edit_page_id => @edit_page_node.id}
    @rnd = generate_page_renderer('list', options, inputs)
    @rnd.should_receive(:jobs_list_edit_list_feature).and_return('')
    renderer_get @rnd
  end

  it "should be able to render the write page" do
    inputs = { :target => [:container, @post] }
    options = {:list_page_id => @list_page_node.id}
    @rnd = generate_page_renderer('write', options, inputs)
    @rnd.should_receive(:jobs_list_edit_write_feature).and_return('')
    renderer_get @rnd
  end

end
