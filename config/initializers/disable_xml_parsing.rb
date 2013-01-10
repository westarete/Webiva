# Workaround for security hole.
# Ref: https://groups.google.com/forum/?fromgroups=#!topic/rubyonrails-security/61bkgvnSGTQ

ActionController::Base.param_parsers.delete(Mime::XML) 
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('symbol') 
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('yaml') 

