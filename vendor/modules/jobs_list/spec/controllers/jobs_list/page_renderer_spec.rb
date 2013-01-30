require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"


describe JobsList::PageRenderer, :type => :controller do
  controller_name :page
  
  integrate_views

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/jobs_list/page/' + paragraph, options, inputs)
  end

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    mock_editor
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
    @category = @jobs_list.jobs_list_categories.create :name => 'new'
    @post = @jobs_list.jobs_list_posts.new  :title => 'Test Post', :body => 'Test Body'
    @post.save
  end

  it "should be able to list posts" do
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    options = {:jobs_list_id => @jobs_list.id, :detail_page => @detail_page_node.id}
    @rnd = generate_page_renderer('entry_list', options)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to list posts from jobs_list_id page connection" do
    options = {}
    inputs = { :jobs_list => [:jobs_list_id, @jobs_list.id] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to list posts from target page connection" do
    @jobs_list.is_user_jobs_list = true
    @jobs_list.target = @post
    @jobs_list.save.should be_true

    options = { :jobs_list_target_id => @jobs_list.jobs_list_target_id}
    inputs = { :jobs_list => [:container, @post] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_target_type_and_target_id).with(@post.class.to_s, @post.id,:conditions => { :jobs_list_target_id => @jobs_list.jobs_list_target_id } ).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type category" do
    options = {:jobs_list_id => @jobs_list.id}
    inputs = { :type => [:list_type, 'category'], :identifier => [:list_type_identifier, 'new2'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)
    @rnd.should_receive(:set_page_connection).with(:category,'new2')

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type tag" do
    options = {:jobs_list_id => @jobs_list.id}
    inputs = { :type => [:list_type, 'tag'], :identifier => [:list_type_identifier, 'yourit'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to list posts with list_type archive" do
    options = {:jobs_list_id => @jobs_list.id}
    inputs = { :type => [:list_type, 'archive'], :identifier => [:list_type_identifier, 'January2010'] }
    @rnd = generate_page_renderer('entry_list', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink" do
    list_page_node = SiteVersion.default.root.add_subpage('list')
    options = {:jobs_list_id => @jobs_list.id, :list_page_id => list_page_node.id}
    inputs = { :input => [:post_permalink, @post.permalink] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)
    @jobs_list.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    @rnd.should_receive(:set_page_connection).with(:content_id, ['JobsList::JobsListPost',@post.id])
    @rnd.should_receive(:set_page_connection).with(:post, @post.id)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink using jobs list target" do
    @jobs_list.is_user_jobs_list = true
    @jobs_list.target = @post
    @jobs_list.save.should be_true

    options = { :jobs_list_target_id => @jobs_list.jobs_list_target_id }
    inputs = { :input => [:post_permalink, @post.permalink], :jobs_list => [:container, @post] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_target_type_and_target_id).with(@post.class.to_s, @post.id,:conditions => { :jobs_list_target_id => @jobs_list.jobs_list_target_id }).and_return(@jobs_list)
    @jobs_list.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    renderer_get @rnd
  end

  it "should be able to display a post by permalink using jobs list id" do
    options = {}
    inputs = { :input => [:post_permalink, @post.permalink], :jobs_list => [:jobs_list_id, @jobs_list.id] }
    @rnd = generate_page_renderer('entry_detail', options, inputs)

    JobsList::JobsListJobsList.should_receive(:find_by_id).with(@jobs_list.id).and_return(@jobs_list)
    @jobs_list.should_receive(:find_post_by_permalink).with(@post.permalink).and_return(@post)

    renderer_get @rnd
  end

  it "should be able to list categories for a jobs list" do
    @list_page_node = SiteVersion.default.root.add_subpage('list')
    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    options = {:jobs_list_id => @jobs_list.id, :list_page_id => @list_page_node.id, :detail_page_id => @detail_page_node.id}
    @rnd = generate_page_renderer('categories', options)
    renderer_get @rnd
  end
end
