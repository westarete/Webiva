# Copyright (C) 2009 Pascal Rettig.

require 'hpricot'

class JobsList::JobsListPostRevision < DomainModel

  validates_presence_of :title

  belongs_to :jobs_list_post, :class_name => 'JobsList::JobsListPost', :foreign_key => 'jobs_list_post_id'

  
  apply_content_filter(:body => :body_html)  do |revision|
    { :filter => revision.jobs_list_jobs_list.content_filter }
  end

  attr_writer :jobs_list_jobs_list
  def jobs_list_jobs_list
    @jobs_list_jobs_list || self.jobs_list_post.jobs_list_jobs_list
  end

  def body_content
    self.body_html.blank? ? self.body : self.body_html
  end
  
 # Generate text from HTML
 def text_generator(html)
   link_sanitizer = HTML::LinkSanitizer.new
   link_sanitizer.sanitize(CGI::unescapeHTML(html.to_s.gsub(/\<\/(p|br|div)\>/," </\\1>\n ").gsub(/\<(h1|h2|h3|h4)\>(.*?)<\/(h1|h2|h3|h4)\>/) do |mtch|
        "\n#{$2}\n#{'=' * $2.length}\n\n"
    end.gsub("<br/>","\n")).gsub("&nbsp;"," "))
 end

 def ae_some_html(s)
    return if s.blank?
    
    s = strip_word(s)
    sanitizer = HTML::WhiteListSanitizer.new
    sanitizer.sanitize(s)
  end
  
  def strip_word(txt)
     cleanMso = Proc.new { |b| b = b.replace(/\bMso[\w\:\-]+\b/m, '') ? ' class="' + b + '"' : '' }
     
     regx = [  /^\s*( )+/m,                                              # nbsp entities at the start of contents
              /( |<br[^>]*>)+\s*$/m,                                     # nbsp entities at the end of contents
              /<!--\[(end|if)([\s\S]*?)-->|<style>[\s\S]*?<\/style>/mi,  # Word comments
              /<\/?(font|meta|link)[^>]*>/mi,                            # Fonts, meta and link
              /<\\?\?xml[^>]*>/mi,                                       # XML islands
              /<\/?o:[^>]*>/mi,                                          # MS namespaced elements <o:tag>
              /<\/?w:[^>]*>/mi,                                          # MS namespaced elements <o:tag>
              [/ class=\"([^\"]+)\"/mi, ''],                       # All classes like MsoNormal
              [/ class=([\w\:\-]+)/mi, ''],                        # All classes like MsoNormal
              / style=\"([^\"]+)\"| style=[\w\:\-]+/mi,                  # All style attributes
              [/<(\/?)s>/i, '<$1strike>']                              # Convert <s> into <strike> for line-though
                        ]
                        
      regx.each do |reg|
        if(reg.is_a?(Array))
          txt.gsub!(reg[0],reg[1])
        else
          txt.gsub!(reg,'')
        end
      end  
      
      
      txt                      
  end
end
