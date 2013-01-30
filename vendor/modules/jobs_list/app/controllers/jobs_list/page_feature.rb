# Copyright (C) 2009 Pascal Rettig.



class JobsList::PageFeature < ParagraphFeature

  feature :jobs_list_entry_list, :default_feature => <<-FEATURE
    <cms:entries>
      <cms:entry>
        <div class='jobs_list_entry'>
          <cms:image align='left' border='10' size='preview' shadow='1' />
          <h2><cms:detail_link><cms:title/></cms:detail_link></h2>
          <cms:preview/>
          <cms:more><cms:detail_link>Read More...</cms:detail_link><br/><br/></cms:more>
          <div class='jobs_list_info'>
             Posted <cms:published_at /> by <cms:author/> | <cms:detail_link>User Comments (<cms:comment_count/>)</cms:detail_link><br/><br/>
             <cms:categories> Categories: <cms:value/> <cms:tags> | </cms:tags> </cms:categories> 
             <cms:tags> Tags: <cms:value/> </cms:tags>
          </div>
        </div>
        <div style='clear:both;'></div>
        <cms:not_last><hr/></cms:not_last>
      </cms:entry>
      <cms:pages/>
    </cms:entries>
  FEATURE

  def jobs_list_entry_list_feature(data)
    webiva_feature('jobs_list_entry_list') do |c|
      c.value_tag 'title' do |tag|
        exists = !data[:type].blank? && !data[:identifier].blank?
        tag.locals.value = "Showing #{data[:type]} &gt; #{data[:identifier]}"
        tag.single? ? tag.locals.value : (exists ? tag.expand : nil)
      end

      c.link_tag('list_page') { |tag| data[:list_page] }

      c.loop_tag('grouping') do |t|
        by = t.attr['by'] || "%B %Y"
        # Get a list of entries of the form [ [ "May 2009", <Entry> ], ... ]
        entries = data[:entries].select(&:published_at).map { |entry| [ entry.published_at.localize(by), entry ] }

        # Now group the entries, keeping the same order
        # [ [ "May 2009", [ <Entry1>, <Entry2> ], ... ]
        entries.inject([]) do |acc,entry|
          if acc[-1] && acc[-1][0] == entry[0]
            acc[-1][1] << entry[1]
          else
            acc << [ entry[0], [ entry[1] ] ]
          end
          acc
        end
      end
      c.value_tag('grouping:header') { |t| t.locals.grouping[0] }


      c.loop_tag('entry') { |t| t.locals.grouping ? t.locals.grouping[1] : data[:entries] }
        jobs_list_entry_tags(c,data)

      c.pagelist_tag('pages') { |t| data[:pages] }
    end
  end

  feature :jobs_list_entry_detail, :default_feature => <<-FEATURE
      <cms:entry>
        <div class='jobs_list_entry'>
          <cms:image align='left' border='10' size='preview' shadow='1' />
          <h1><cms:title/></h1>
          <cms:body/>
        </div>
          <cms:embedded_media>
            <div style='clear:both;'></div>
            <br/><br/>
            <div align='center'><cms:value/></div>
            <br/>
          </cms:embedded_media>
          <cms:media_file>
            <div style='clear:both;'></div>
            <br/><br/>
            <div style='text-align:center;'><cms:value/></div>
          </cms:media_file>
          <div class='jobs_list_info'>
             Posted <cms:published_at /> by <cms:author/> <br/>
             <cms:categories>Categories: <cms:value/> <cms:tags>|</cms:tags> </cms:categories> 
             <cms:tags>Tags: <cms:value/></cms:tags>
          </div>
        <div style='clear:both;'></div>
      </cms:entry>
      <cms:no_entry>Invalid Post</cms:no_entry>
  FEATURE
  
  def jobs_list_entry_detail_feature(data)
    webiva_feature('jobs_list_entry_detail') do |c|
      c.link_tag('list_page') { |tag| data[:list_page] }
      c.expansion_tag('entry') { |tag| tag.locals.entry = data[:entry] }
        jobs_list_entry_tags(c,data)
   end
  end   

  def jobs_list_entry_tags(c,data)
    c.value_tag('jobs_list_name') { |t| data[:jobs_list].name }
    c.value_tag('jobs_list_description') { |t| data[:jobs_list].description }
    c.value_tag('jobs_list_target_id') { |t| data[:jobs_list].target_id }
    
    
    c.value_tag('entry:jobs_list') { |t| t.locals.entry.jobs_list_jobs_list.name  }
    c.value_tag('entry:embedded_media') { |tag| tag.locals.entry.embedded_media }
    
    c.media_tag('entry:media_file') { |tag| tag.locals.entry.media_file }

    c.value_tag('entry:rating') { |t| (t.locals.entry.rating * (t.attr['multiplier'] || 1).to_i).floor.to_i }
    c.value_tag('entry:rating_display') { |t| sprintf("%.1f",t.locals.entry.rating) }
    
    c.date_tag('entry:published_at',"%H:%M%p on %B %d %Y".t) { |t|  t.locals.entry.published_at }
    c.image_tag('entry:image') { |t| t.locals.entry.image }
    c.expansion_tag('entry:comments') { |t| t.locals.entry.comments_count > 0 }
    c.value_tag('entry:comment_count') { |t| t.locals.entry.comments_count }
    c.value_tag('entry:approved_comment_count') { |t| t.locals.entry.approved_comments_count }
    
    
    %w(title author).each do |elem|
      c.value_tag('entry:' + elem) { |tag| h(tag.locals.entry.send(elem)) }
    end
    
    c.value_tag('entry:id') { |t| t.locals.entry.id }
    c.value_tag('entry:permalink') { |t| t.locals.entry.permalink }
    c.value_tag('entry:body') { |tag| tag.locals.entry.body_content }
    c.value_tag('entry:preview') {  |tag| tag.locals.entry.preview_content }
    c.value_tag('entry:content_node_id') { |t| t.locals.entry.content_node.id }

    c.value_tag 'entry:preview_title' do |tag|
      h(tag.locals.entry.preview_title.blank? ? tag.locals.entry.title : tag.locals.entry.preview_title)
    end

    c.expansion_tag('entry:more') { |tag| !tag.locals.entry.preview.blank? }
    c.link_tag('entry:detail') do |tag| 
      if !data[:detail_page].blank?
        SiteNode.link data[:detail_page], tag.locals.entry.permalink
      else
        tag.locals.entry.content_node.link if tag.locals.entry.content_node
      end
    end
    c.link_tag('entry:full_detail') { |tag| "#{SiteNode.domain_link(data[:detail_page], tag.locals.entry.permalink)}" }

    c.value_tag('entry:categories') do |tag|
      categories = tag.locals.entry.jobs_list_categories(true).collect(&:name)
      categories = categories[0..tag.attr['limit'].to_i] if tag.attr['limit']
      if categories.length > 0
        tag.locals.categories = categories
        categories = categories.map { |cat| "<a href='#{SiteNode.link(data[:list_page], 'category', CGI::escape(cat))}'>#{h cat}</a>" } unless tag.attr['no_link']
      	categories.join(", ")
      else 
      	nil
      end
    end

    c.loop_tag('entry:categories:category') { |t| t.locals.categories }
    c.link_tag('entry:categories:category:') { |t| SiteNode.link(data[:list_page], 'category', CGI::escape(t.locals.category)) }
    c.value_tag('entry:categories:category:name') { |t| t.locals.category }
    c.value_tag('entry:categories:category:escaped_name') { |t| CGI::escape(t.locals.category) }

    c.value_tag('entry:tags') do |tag|
      tags = tag.locals.entry.content_tags
      if tags.length > 0
	tags.collect {|tg| "<a href='#{SiteNode.link(data[:list_page], 'tag', h(tg.name))}'>#{h tg.name}</a>" }.join(", ")
      else
	nil
      end
    end

    if data[:jobs_list] && data[:jobs_list].content_publication
      c.expansion_tag('entry:content') { |tag| tag.locals.form = tag.locals.entry.data_model }
      c.publication_field_tags('entry:content', data[:jobs_list].content_publication)
    end
  end

  feature :jobs_list_categories, :default_feature => <<-FEATURE
<cms:categories>
  <cms:category>
    <cms:category_link selected_class='selected'><cms:name/></cms:category_link><br/>
  </cms:category>
</cms:categories>
<br/><br/>
<cms:recent_entries>
  <h4>Recent Posts</h4>
  <cms:entry>
    <cms:detail_link><cms:title/></cms:detail_link><br/>
  </cms:entry>
</cms:recent_entries>
<br/><br/>
<cms:archives>
  <h4>Archives</h4>
  <cms:archive>
    <cms:archive_link><cms:date format='%B %Y'/> (<cms:count/>)</cms:archive_link><br/>
  </cms:archive>
</cms:archives>
   FEATURE
   
  def jobs_list_categories_feature(data)
    webiva_feature('jobs_list_categories') do |c|

      c.loop_tag('category') { |tag| data[:categories] }

      c.link_tag('category:category') { |tag| "#{SiteNode.link(data[:list_page], 'category', CGI::escape(tag.locals.category.name))}" }
      
      c.expansion_tag 'category:selected' do |tag|
	tag.locals.category.name == data[:selected_category].to_s
      end
      
      c.value_tag("category:name") { |tag| h(tag.locals.category.name) }

      c.loop_tag('entry', 'recent_entries') do |tag|
	if ! @recent_posts
	  limit = (tag.attr['limit'] || 5).to_i
	  @recent_posts =  JobsList::JobsListPost.find(:all,:include => [ :active_revision ], :order => 'published_at DESC',:conditions => ['jobs_list_posts.status = "published" AND jobs_list_posts.published_at < ? AND jobs_list_jobs_list_id=?',Time.now,data[:jobs_list_id]], :limit => limit)
	end

	@recent_posts
      end 

      jobs_list_entry_tags(c,data)

      c.loop_tag('archive') do |tag|
	if !@archives
	  limit = (tag.attr['limit'] || 5).to_i
	  @archives = JobsList::JobsListPost.find(:all,:select => "DATE_FORMAT(published_at,'%Y-%m') as date_grouping, COUNT(id) as cnt", :order => 'published_at DESC',:group => 'date_grouping',:conditions => ['jobs_list_posts.status = "published" AND jobs_list_posts.published_at < ? AND jobs_list_jobs_list_id=?',Time.now,data[:jobs_list_id]]).collect do |arch|
	    dt = arch.date_grouping.split("-")
	    { :date => Time.mktime(dt[0].to_i,dt[1].to_i),
	      :cnt => arch.cnt }
	  end
	end
	
	@archives
      end
      
      c.link_tag('archive:archive') do |tag|
	formatted = tag.locals.archive[:date].strftime("%B%Y")
	"#{SiteNode.link(data[:list_page], 'archive', formatted)}"
      end

      c.datetime_tag('archive:date') { |tag| tag.locals.archive[:date] }

      c.define_value_tag "archives:archive:count" do |tag|
	tag.locals.archive[:cnt]
      end


      c.loop_tag('author') do |tag|
        JobsList::JobsListPost.find(:all,
                            :include => ['active_revision'],
                            :conditions => {'jobs_list_posts.status' => 'published',
                                            'jobs_list_post_revisions.status' => 'active',
                                            :jobs_list_jobs_list_id => data[:jobs_list_id]},
                            :order => 'jobs_list_post_revisions.author',
                            :group => 'jobs_list_post_revisions.author')
      end

      c.link_tag('author:author') do |tag|
        SiteNode.link(data[:list_page], 'author', CGI::escape(tag.locals.author.author))
      end

      c.value_tag('author:name') { |tag| tag.locals.author.author }

      c.link_tag('list_page') { |tag| data[:list_page] }
    end
  end

  feature :jobs_list_post_preview, :default_feature => <<-DEFAULT_FEATURE
<cms:entry>
<cms:image align='left' size='thumb'/><cms:preview/>
</cms:entry>
DEFAULT_FEATURE

  def jobs_list_post_preview_feature(data)
    webiva_feature(:jobs_list_post_preview) do |c|
       c.expansion_tag('entry') { |t| t.locals.entry = data[:entry] }
       jobs_list_entry_tags(c,data)
    end
  end
end


