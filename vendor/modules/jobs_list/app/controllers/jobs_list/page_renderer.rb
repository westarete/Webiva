# Copyright (C) 2009 Pascal Rettig.

class JobsList::PageRenderer < ParagraphRenderer

  module_renderer
  
  paragraph :entry_list
  paragraph :entry_detail
  paragraph :categories
  paragraph :targeted_entry_detail
  
  features '/jobs_list/page_feature'

  def get_module
    @mod = JobsList::PageRenderer.get_module
  end

  def self.get_module
    mod = SiteModule.get_module('jobs_list')
    
    mod.options ||= {}
    mod.options[:field] ||= []
    mod.options[:options] ||= {}
    
    mod
  end

  def entry_list
    @options = paragraph_options(:entry_list)

    page = (params[:page] || 1).to_i
    page = 1 if page < 1

    # .../category/something
    # list_type = category, list_type_identifier = something
    list_connection_type,list_type = page_connection(:type)

    list_connection_detail,list_type_identifier  = page_connection(:identifier)

    if list_type == 'category'
      category_filter  = list_type_identifier
    elsif list_type == 'tag'
      tag_filter = list_type_identifier
    elsif list_type == 'author'
      author_filter = CGI.unescape(list_type_identifier) # Author name
    end

    list_connection_detail, category_filter = page_connection(:category) if page_connection(:category)
    tag_type, tag_filter =  page_connection(:tag) if page_connection(:tag)

    if list_type && ! editor?
      list_type = list_type.downcase unless list_type.blank?
      unless (['author','category','tag','archive'].include?(list_type.to_s))
        raise SiteNodeEngine::MissingPageException.new(site_node, language) if list_type_identifier && site_node.id == @options.detail_page_id
        set_page_connection(:category, nil)
        return render_paragraph :text => ''
      end
    end

    if category_filter
      category_filter = category_filter.to_s.gsub("+"," ")
      set_page_connection(:category, category_filter)
    else
      set_page_connection(:category, nil)
    end

    type_hash = DomainModel.hexdigest("#{list_type}_#{list_type_identifier}_#{category_filter}_#{tag_filter}")
    display_string = "#{page}_#{type_hash}"

    result = renderer_cache(JobsList::JobsListPost, display_string) do |cache|
      if !@options.category.blank? && @options.limit_by == "category"
        category_filter = @options.category.split(",").map(&:strip).reject(&:blank?)
      elsif !@options.category.blank? && @options.limit_by == "tag"
        tag_filter = @options.category.split(",").map(&:strip).reject(&:blank?)
      end

      jobs_list = get_jobs_list
      return render_paragraph :text => (@options.jobs_list_id.to_i > 0 ? '[Configure paragraph]' : '') unless jobs_list || @options.jobs_list_id == -1

      detail_page =  get_detail_page
      items_per_page = (@options.items_per_page || 1).to_i
      
      entries = []
      pages = {}
  
      if jobs_list
        if list_type.to_s == 'archive'
          pages,entries = jobs_list.paginate_posts_by_month(page,list_type_identifier,items_per_page,:large => @options.skip_total)
        elsif list_type.to_s == 'author'
          pages,entries = jobs_list.paginate_posts_by_author(page,author_filter,items_per_page,:large => @options.skip_total)
        else
          pages,entries = jobs_list.paginate_posts(@options.skip_page ? 1 : page,items_per_page,:large => @options.skip_total, :category_filter => category_filter, :tag_filter => tag_filter, :order => @options.order == 'date' ? 'jobs_list_posts.published_at DESC' : 'jobs_list_posts.rating DESC')
        end
      else
        pages,entries = JobsList::JobsListPost.paginate_published(page,items_per_page,@options.jobs_list_ids,:large => @options.skip_total)
      end

      cache[:title] = jobs_list.name if jobs_list
      cache[:output] = jobs_list_entry_list_feature(:jobs_list => jobs_list,
					       :entries => entries,
					       :detail_page => detail_page,
					       :list_page => @options.list_page_url || site_node.node_path,
					       :pages => pages,
					       :type => list_type,
					       :identifier => list_type_identifier)
    end

    set_title(result.title) if result.title 
    require_css('gallery')
    render_paragraph :text => result.output
  end

  def entry_detail
    @options = paragraph_options(:entry_detail)

    jobs_list = get_jobs_list
    return render_paragraph :text => (@options.jobs_list_id.to_i > 0 ? '[Configure paragraph]' : '') unless jobs_list

    conn_type, conn_id = page_connection()
    display_string = "#{conn_type}_#{conn_id}_#{myself.user_class_id}"

    result = renderer_cache(jobs_list, display_string) do |cache|
      entry = nil
      if editor?
        entry = jobs_list.jobs_list_posts.find(:first,:conditions => ['jobs_list_posts.status = "published" AND jobs_list_jobs_list_id=? ',jobs_list.id])
      elsif conn_type == :post_permalink
        entry = jobs_list.find_post_by_permalink(conn_id)
      end

      cache[:content_node_id] = entry.content_node.id if entry && entry.content_node
      cache[:output] = jobs_list_entry_detail_feature(:entry => entry,
                                                 :list_page => get_list_page(jobs_list),
                                                 :jobs_list => jobs_list)
      cache[:title] = entry ? entry.title : ''
      cache[:keywords] = (entry && !entry.keywords.blank?) ? entry.keywords : nil
      cache[:entry_id] = entry ? entry.id : nil
      cache[:comments_ok] = entry ? ! entry.disallow_comments : true
    end

    if result.entry_id
      set_page_connection(:content_id, ['JobsList::JobsListPost',result.entry_id] )
      set_page_connection(:content_node_id, result.content_node_id )
      set_page_connection(:post, result.entry_id )
      set_page_connection(:comments_ok, result.comments_ok)
      set_title(result.title)
      set_content_node(result.content_node_id)
      html_include('meta_keywords',result.keywords) if result.keywords 
    else
      return render_paragraph :text => '' if (['', 'category','tag','archive'].include?(conn_id.to_s.downcase)) && site_node.id == @options.list_page_id
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless editor?
    end

    require_css('gallery')

    render_paragraph :text => result.output
  end

  def targeted_entry_detail
    @options = paragraph_options(:targeted_entry_detail)
    return render_paragraph :text => "[Configure Paragraph]" unless @options.jobs_list_target_id > 0

    jobs_list = get_jobs_list

    return render_paragraph :text => '' unless jobs_list

    conn_type, conn_id = page_connection()
    display_string = "#{conn_type}_#{conn_id}_#{myself.user_class_id}"

    result = renderer_cache(jobs_list, display_string) do |cache|
      entry = nil
      if editor?
        entry = jobs_list.jobs_list_posts.find(:first,:conditions => ['jobs_list_posts.status = "published" AND jobs_list_jobs_list_id=? ',jobs_list.id])
      elsif conn_type == :post_permalink
        entry = jobs_list.find_post_by_permalink(conn_id) if conn_id
      end

      cache[:output] = jobs_list_entry_detail_feature(:entry => entry,
                                                 :list_page => get_list_page(jobs_list),
                                                 :detail_page => site_node.node_path,
                                                 :jobs_list => jobs_list)
      cache[:title] = entry ? entry.title : ''
      cache[:entry_id] = entry ? entry.id : nil
    end

    if result.entry_id
      set_page_connection(:content_id, ['JobsList::JobsListPost',result.entry_id] )
      set_page_connection(:post, result.entry_id )
      set_title(result.title)
      set_content_node(['JobsList::JobsListPost', result.entry_id])
    else
      raise SiteNodeEngine::MissingPageException.new( site_node, language ) unless editor?
    end

    require_css('gallery')

    render_paragraph :text => result.output
  end






  def categories
    @options = paragraph_options(:categories)
    
    category_connection,selected_category_name = page_connection()
    selected_category_name = nil unless category_connection == 'category'

    display_string = "#{category_connection}_#{selected_category_name}"

    result = renderer_cache(JobsList::JobsListJobsList, display_string) do |cache|
      @categories = JobsList::JobsListCategory.find(:all, :conditions => {:jobs_list_jobs_list_id => @options.jobs_list_id}, :order => 'name')
      
      cache[:output] =  jobs_list_categories_feature(:list_page => @options.list_page_url,
						:detail_page => @options.detail_page_url,
						:categories => @categories, 
						:selected_category => selected_category_name,
						:jobs_list_id => @options.jobs_list_id
						)
    end
    
    render_paragraph :text => result.output
  end

  protected

  def get_jobs_list
    if @options.jobs_list_id.to_i < 0
      nil
    elsif @options.jobs_list_id.to_i > 0
      JobsList::JobsListJobsList.find_by_id(@options.jobs_list_id.to_i)
    elsif editor?
      jobs_list = JobsList::JobsListJobsList.find(:first)
    else
      conn_type, conn_id = page_connection(:jobs_list)
      if conn_type == :container
        JobsList::JobsListJobsList.find_by_target_type_and_target_id(conn_id.class.to_s, conn_id.id,:conditions => {:jobs_list_target_id => @options.jobs_list_target_id})
      elsif conn_type == :jobs_list_id
        JobsList::JobsListJobsList.find_by_id(conn_id.to_i)
      end
    end
  end

  def get_detail_page
    detail_page =  @options.detail_page_url
    return nil unless detail_page
    if @options.include_in_path == 'jobs_list_id'
      detail_page += "/#{jobs_list.id}"
    elsif  @options.include_in_path == 'target_id'
      detail_page += "/#{jobs_list.target_id}"
    end
    SiteNode.link detail_page
  end

  def get_list_page(jobs_list)
    list_page =  @options.list_page_url
    return nil unless list_page
    if jobs_list
      if @options.include_in_path == 'jobs_list_id'
        list_page += "/#{jobs_list.id}"
      elsif  @options.include_in_path == 'target_id'
        list_page += "/#{jobs_list.target_id}"
      end
    end
    SiteNode.link list_page
  end
end
