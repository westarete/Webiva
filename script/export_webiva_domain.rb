#!/usr/bin/env ruby 

# export_webiva_domain.rb - Dump a Webiva domain in order to copy to a new site

require "rubygems"
require "date"
require "dbi"
require 'highline/import'
require 'pathname'
require "pp"


def usage()
   puts "Usage: export_webiva_domain [-d -h -v]\n"
   puts "\t -b \t\t#{$beta_environment_string}"
   puts "\t -d \t\tEnable debug output"
   puts "\t -f \t\tName of export file [include path if necessary]"
   puts "\t -h \t\tPrint usage summary"
   puts "\t -p \t\t#{$production_environment_string}"
   puts "\t -s \t\t#{$staging_environment_string}"
   puts "\t -v \t\tEnable verbose output"
   exit
end

# Get command line options, initialize variables

debug = false
verbose = false

output_filename = "none"
hostname = `/bin/hostname`.strip
environment = "beta"
$staging_environment_string = "Set environment to staging"
$beta_environment_string = "Set environment to beta [default]"
$production_environment_string = "Set environment to production"

   # Modify default environment for some hosts

case hostname
   when 'alexander.westarete.com'
      environment = "production"
      $staging_environment_string = "Set environment to staging"
      $beta_environment_string = "Set environment to beta"
      $production_environment_string = "Set environment to production [default]"
   when 'shiitake.westarete.com'
      environment = "production"
      $staging_environment_string = "Set environment to staging"
      $beta_environment_string = "Set environment to beta"
      $production_environment_string = "Set environment to production [default]"
   when 'otter.westarete.com'
      environment = "beta"
      $staging_environment_string = "Set environment to staging"
      $beta_environment_string = "Set environment to beta [default]"
      $production_environment_string = "Set environment to production"
   when 'tussey.westarete.com'
      environment = "staging"
      $staging_environment_string = "Set environment to staging [default]"
      $beta_environment_string = "Set environment to beta"
      $production_environment_string = "Set environment to production"
end

while ARGV.length > 0 do
   case ARGV[0].to_s
      when "-b" then 
         environment = "beta"
      when "-d" then 
         debug = true
      when "-f" then 
         ARGV.shift
         output_filename = ARGV[0]
      when "-h" then 
         usage
      when "-p" then 
         environment = "production"
      when "-s" then 
         environment = "staging"
      when "-v" then 
         verbose = true
   end
   ARGV.shift
end

webroot = "/var/www/domains/webiva." + environment + ".westarete.com/"
puts "Webroot: " + webroot if debug

if !(File.exists?(webroot) && File.directory?(webroot))
  puts "The web root " + webroot + " does not exist or is not a directory - exiting!"
  exit
end

# Check for pre-existing files in the backup directory; exit if there are any

filelist = `/bin/ls #{webroot}current/backup/2* 2>/dev/null`.chop

if filelist != "" then
  puts "\nThere are already backup/export files in #{webroot}current/backup."
  puts "Please remove them before proceeding.\n\n"
  exit
end

puts "\nTo continue, you will need the name and password of a database user with read access to the Webiva databases.\n\n"
print "Enter database user: "
dbuser = gets.chop
dbpassword = ask("Enter password: ") { |q| q.echo = false }

begin

# connect to the MySQL server
   dbh = DBI.connect("DBI:Mysql:webiva:localhost", "#{dbuser}", "#{dbpassword}" )

# Get a list of the Webiva domain database names and their YAML config options
   domain_databases = dbh.select_all("SELECT name,options FROM domain_databases")

if debug then
  puts "domain_databases: "
  pp domain_databases
  puts " "
end

# Display a list of Webiva site databases to the user and see which one they
# want to export

domain_info=Array.new
domain_info[0]=Hash.new
domain_info[0]["dbname"] = "placeholder"
domain_info[0]["filestore"] = "placeholder"
domain_counter = 0

domain_databases.each do |db|
  next if db[0] == ""
  domain_counter += 1
  pp db[0] if debug
  pp db[1] if debug
  filestorestring = /.*file_store: (.*).*/.match(db[1])
  filestore = filestorestring.to_s.split(" ")[1]

  if debug then 
    puts "filestorestring: " + filestorestring.to_s
    puts "filestore: " + filestore.to_s
    puts " "
  end

  domain_info[domain_counter] = Hash.new
  domain_info[domain_counter]["dbname"] = db[0]
  domain_info[domain_counter]["filestore"] = filestore.to_s
  
end

domain_counter = 1
puts "\n\nIndex\t\tDatabase\t\t\tFilestore\n\n"
domain_info.each do |entry|
  next if entry["dbname"] == "placeholder"
  puts domain_counter.to_s + "\t" + entry["dbname"] + "\t" + entry["filestore"]
  domain_counter += 1
end

print "\n\nPlease enter the index number of the Webiva db you want to back up or migrate\nto a new host: "
userindex = gets.chop.to_i

# Export the Webiva site and tell the user where to find the export tarball and what to do next

cmd = "(cd #{webroot}current && rake cms:backup DOMAIN_ID=" + domain_info[userindex]["filestore"] + " NO_COPY=1)"

puts "\nWe will run the command : '" + cmd + "'"
print "\nIs this what you would like to do? [yN]: "
confirm = gets.chop

if confirm == "y" || confirm == "Y" then
  system(cmd)
  filelist = `/bin/ls #{webroot}current/backup/2*`.chop

  if output_filename == "none" then
    destfile = "/tmp/" + Pathname.new(filelist).basename
  else
    destfile = output_filename
  end

  puts "\n\nMoving " + filelist + " to " + destfile
  cmd = "mv " + filelist + " " + destfile
  system(cmd)
  puts "\nNow, copy " + destfile + " to the target Webiva host and run import_webiva_domain.rb to import the domain"
end

puts "\n\n"

exit

rescue DBI::DatabaseError => e
   puts "A database access error occurred:"
   puts "Error code: #{e.err}"
   puts "Error message: #{e.errstr}"
ensure
   # disconnect from server
   dbh.disconnect if dbh
end

