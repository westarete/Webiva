require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"

describe JobsList::PageFeature, :type => :view do

  reset_domain_tables :jobs_list_jobs_lists, :jobs_list_posts, :jobs_list_post_revisions, :jobs_list_posts_categories, :jobs_list_categories, :content_nodes, :content_types, :site_nodes

  before(:each) do
    @jobs_list = JobsList::JobsListJobsList.create(:name => 'Test Jobs List', :content_filter => 'full_html')
    @category = @jobs_list.jobs_list_categories.create :name => 'new'
    @post = @jobs_list.jobs_list_posts.new :title => 'Test Post', :body => 'Test Body'

    @post.publish(5.minutes.ago)
    @post.save
    @feature = build_feature('/jobs_list/page_feature')

    @detail_page_node = SiteVersion.default.root.add_subpage('detail')
    @list_page_node = SiteVersion.default.root.add_subpage('list')
  end

  it "should render a entry list paragraph" do
    pages,entries = @jobs_list.paginate_posts(1,10)

    @output = @feature.jobs_list_entry_list_feature(:jobs_list => @jobs_list,
					       :entries => entries,
					       :detail_page => @detail_page_node.node_path,
					       :list_page => @list_page_node.node_path,
					       :pages => pages,
					       :type => nil,
					       :identifier => nil
					       )

    @output.should include( @post.title )
  end

  it "should render a entry detail paragraph" do
    @output = @feature.jobs_list_entry_detail_feature(:entry => @post,
						 :jobs_list => @jobs_list,
						 :detail_page => @detail_page_node.node_path,
						 :list_page => @list_page_node.node_path
						 )

    @output.should include( @post.title )
  end

  it "should render a categories paragraph" do
    @categories = @jobs_list.jobs_list_categories.find(:all)

    @output = @feature.jobs_list_categories_feature(:detail_page => @detail_page_node.node_path,
					       :list_page => @list_page_node.node_path,
					       :categories => @categories,
					       :selected_category => @category.name,
					       :jobs_list_id => @jobs_list.id
					       )

    @output.should include( @category.name )
    @output.should include( @post.title )
  end

  it "should render a preview paragraph" do
    @post.preview = 'Preview Test'

    @output = @feature.jobs_list_post_preview_feature(:entry => @post
						 )

    @output.should include( 'Preview Test' )
  end
end
