# Force usage of json gem to avoid security hole.
# Ref: http://weblog.rubyonrails.org/2013/1/28/Rails-3-0-20-and-2-3-16-have-been-released/
ActiveSupport::JSON.backend = "JSONGem" 

