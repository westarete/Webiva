# Copyright (C) 2009 Pascal Rettig.



class JobsList::EditRenderer < ParagraphRenderer

  features '/jobs_list/edit_feature'

  paragraph :list, :ajax => true
  paragraph :write

  include EndUserTable::Controller
  
  

  def list
    @options = paragraph_options(:list)
    
    conn_type,conn_id = page_connection(:input)

    target_conn_type,target_conn_id = page_connection(:target_url)
    if !target_conn_id.blank?
      @target_connection_url = "/#{target_conn_id}"
    end

    if editor?
      @jobs_list = JobsList::JobsListJobsList.find(:first,:conditions => "is_user_jobs_list = 1")
    else
      @target = conn_id
      @jobs_list = JobsList::JobsListJobsList.find_by_target_type_and_target_id(@target.class.to_s,@target.id) if @target
    end

    if !@jobs_list && @options.auto_create && @target
      @jobs_list = JobsList::JobsListJobsList.create_user_jobs_list(sprintf(@options.jobs_list_name,@target.name),@target)
    end
    
    return render_paragraph(:text => '') if !@jobs_list
 
    @tbl = end_user_table( :post_list,
                             JobsList::JobsListPost,
                             [ 
                              EndUserTable.column(:blank),
                              EndUserTable.column(:string,'jobs_list_post_revisions.title',:label => 'Post Title'),
                              EndUserTable.column(:string,'jobs_list_posts.status',:label => 'Status',:options => JobsList::JobsListPost.status_select_options ),
                              EndUserTable.column(:string,'jobs_list_posts.published_at',:label => 'Published At',:datetime => true )
                             ]
                          )
                             
    end_user_table_action(@tbl) do |act,pids|
     @jobs_list.jobs_list_posts.find(pids).each { |post|  post.destroy } if act == 'delete'
    end

    end_user_table_generate(@tbl,:conditions => [ "jobs_list_jobs_list_id = ?",@jobs_list.id],:order => 'jobs_list_posts.updated_at DESC',:per_page => 20, :include => :active_revision)
  
    edit_url = @options.edit_page_url.to_s + @target_connection_url.to_s
    data = { :tbl => @tbl, :edit_url => edit_url }
    
    render_paragraph :text => jobs_list_edit_list_feature(data)
  end
  
  
  def write
    @options = paragraph_options(:write)

    conn_type,conn_id = page_connection(:target)

    return render_paragraph(:text => '')  if !conn_type

    target_conn_type,target_conn_id = page_connection(:target_url)
    if !target_conn_id.blank?
      @target_connection_url = "/#{target_conn_id}"
    end

    if editor?
      @jobs_list = JobsList::JobsListJobsList.find(:first,:conditions => "is_user_jobs_list = 1")
      @target = @jobs_list.target if @jobs_list
    else
      @target = conn_id
      @jobs_list = JobsList::JobsListJobsList.find_by_target_type_and_target_id(@target.class.to_s,@target.id)
    end

    if !@jobs_list && @options.auto_create && @target
      @jobs_list = JobsList::JobsListJobsList.create_user_jobs_list(sprintf(@options.jobs_list_name,@target.name),@target)
    end

    return render_paragraph(:text => '') if !@jobs_list || !@target

    post_conn_type,post_conn_id = page_connection(:post)

    if post_conn_type == :post_permalink
      @entry = @jobs_list.jobs_list_posts.find_by_permalink(post_conn_id,:include => :active_revision) || @jobs_list.jobs_list_posts.build
    elsif editor?
      @entry= @jobs_list.jobs_list_post.find(:first)
    end

    require_js('tiny_mce/tiny_mce.js')
    require_js('front_cms_form_editor')

      if request.post? && params[:post]

        @published = @entry.published? 
        @entry.attributes = params[:post].slice(:title,:body)
        @entry.permalink = ''
        @entry.end_user_id = myself.id 

        if params[:publish_post].to_i == 1
          @entry.publish_now
        else
          @entry.make_draft
        end

      if @entry.valid?
        @entry.save
        if @entry.published? &&  !@published 
          @handlers = get_handler_info(:jobs_list,:targeted_after_publish)
          @handlers.each do |hndl|
            hndl[:class].send(:after_publish,@entry,myself)
          end

        end
        list_url = @options.list_page_url + @target_connection_url.to_s
        return redirect_paragraph list_url
      end      
    end

    data = { :post => @revision, :entry => @entry, :revision => @revision }
    render_paragraph :text => jobs_list_edit_write_feature(data)
  end


end
