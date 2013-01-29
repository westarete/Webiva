

class JobsList::AddJobsListWizard < WizardModel

  def self.structure_wizard_handler_info
    { :name => "Add a Jobs List to your Site",
      :description => 'This wizard will add an existing jobs list to a url on your site.',
      :permit => "jobs_list_config",
      :url => self.wizard_url
    }
  end

  attributes :jobs_list_id => nil,
  :add_to_id=>nil,
  :add_to_subpage => 'jobs_list',
  :add_to_existing => nil,
  :opts => [],
  :number_of_dummy_posts => 3

  
  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_presence_of :add_to_id

  validates_presence_of :jobs_list_id

  integer_options :number_of_dummy_posts

  options_form(
               fld(:jobs_list_id, :select, :options => :jobs_list_select_options, :label => 'Jobs List to Add'),
               fld(:add_to, :add_page_selector),
               fld(:opts, :check_boxes,
                   :options => [['Add a comments paragraph','comments'],
                                ['Add Categories to list page','categories']],
                   :label => 'Options', :separator => '<br/>'
                   ),
               fld(:number_of_dummy_posts, :text_field, :description => 'Number of dummy posts to create if jobs list has no posts', :label => 'Dummy posts')
               )

  def jobs_list_select_options
    JobsList::JobsListJobsList.select_options_with_nil('Jobs List')
  end

  def validate
    nd = SiteNode.find_by_id(self.add_to_id)
    if (self.add_to_existing.blank? && self.add_to_subpage.blank?)
      self.errors.add(:add_to," must have a subpage selected\nand add to existing must be checked")
    end
    if ( !self.add_to_existing.blank? && ( !nd || nd.node_type == 'R'))
      self.errors.add(:add_to,"you cannot add the jobs list to the site root, please pick a page\nor uncheck 'Add to existing page'")
    end
  end

  def can_run_wizard?
    JobsList::JobsListJobsList.count > 0
  end

  def setup_url
    {:controller => '/jobs_list/admin', :action => 'create', :version => self.site_version_id}
  end

  def set_defaults(params)
    self.jobs_list_id = params[:jobs_list_id].to_i if params[:jobs_list_id]
  end

  def run_wizard
    base_node = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      base_node = base_node.add_subpage(self.add_to_subpage)
    end

    base_node.new_revision do |rv|
      self.destroy_basic_paragraph(rv)

      list_para = rv.push_paragraph('/jobs_list/page', 'entry_list', {:detail_page => base_node.id, :jobs_list_id => self.jobs_list_id}) do |para|
        para.add_page_input(:type, :page_arg_0, :list_type)
        para.add_page_input(:identifier, :page_arg_1, :list_type_identifier)
      end

      detail_para = rv.push_paragraph '/jobs_list/page', 'entry_detail', {:list_page_id => base_node.id, :jobs_list_id => self.jobs_list_id} do |para|
        para.add_page_input(:input, :page_arg_0, :post_permalink)
      end

      if self.opts.include?('comments')
        rv.push_paragraph('/feedback/comments', 'comments',
                          { :show => -1,
                            :allowed_to_post => 'all',
                            :linked_to_type => 'connection',
                            :captcha => false,
                            :order => 'newest'
                          }) do | para|
          para.add_paragraph_input!(:input,detail_para,:content_id,:content_identifier)
        end
      end

      if self.opts.include?('categories')
        rv.push_paragraph('/jobs_list/page','categories',
                          { 
                            :detail_page_id => base_node.id,
                            :jobs_list_id => self.jobs_list_id,
                            :list_page_id => base_node.id
                          },
                          :zone => 3
                          ) do |para|
          para.add_paragraph_input!(:input,list_para,:category,:category)
        end
      end
    end

    # Create Dummy Content
    if self.jobs_list.jobs_list_posts.count == 0 && self.number_of_dummy_posts.to_i > 0
      categories = [self.create_dummy_category(1), self.create_dummy_category(2)]
      (1..self.number_of_dummy_posts).each do |idx|
        self.create_dummy_post(categories[rand(categories.size)])
      end
    end
  end

  def jobs_list
    @jobs_list ||= JobsList::JobsListJobsList.find self.jobs_list_id
  end

  def create_dummy_category(num=1)
    name = DummyText.words(1).split(' ')[0..1].join(' ')
    category = self.jobs_list.jobs_list_categories.create :name => name
    category = self.jobs_list.jobs_list_categories.create(:name => "#{name} #{num}") if category.id.nil?
    category
  end

  def create_dummy_post(cat)
    post = self.jobs_list.jobs_list_posts.create :body => DummyText.paragraphs(1+rand(3), :max => 1), :author => DummyText.words(1).split(' ')[0..1].join(' '), :title => DummyText.words(1), :status => 'published', :published_at => Time.now
    JobsList::JobsListPostsCategory.create :jobs_list_post_id => post.id, :jobs_list_category_id => cat.id
    post
  end
end
