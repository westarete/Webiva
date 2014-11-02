#!/usr/bin/env ruby 

# import_webiva_domain.rb - Import a Webiva domain dump to a site on another 
#                           Webiva server

require "rubygems"
require "date"
require "dbi"
require 'highline/import'
require 'pathname'
require "pp"
require "tmpdir"

def usage()
   puts "Usage: import_webiva_domain [-d -f import_file -h -v]\n"
   puts "\t -b \t\t#{$beta_environment_string}"
   puts "\t -d \t\tEnable debug output"
   puts "\t -f \t\tName of import file [include path if necessary]"
   puts "\t -h \t\tPrint usage summary"
   puts "\t -m \t\tRestart memcached after importing domain"
   puts "\t -p \t\t#{$production_environment_string}"
   puts "\t -s \t\t#{$staging_environment_string}"
   puts "\t -v \t\tEnable verbose output"
   exit
end

# Get command line options, initialize variables

debug = false
input_filename = ""
restart_memcached = "unset"
verbose = false

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
         input_filename = ARGV[0]
      when "-h" then 
         usage
      when "-m" then 
         restart_memcached = "y"
      when "-p" then 
         environment = "production"
      when "-s" then 
         environment = "staging"
      when "-v" then 
         verbose = true
   end
   ARGV.shift
end

if debug then
  puts "environment: " + environment
  puts "input_filename: " + input_filename
end

webroot = "/var/www/domains/webiva." + environment + ".westarete.com/"
puts "Webroot: " + webroot if debug

if !(File.exists?(webroot) && File.directory?(webroot))
  puts "The web root " + webroot + " does not exist or is not a directory - exiting!"
  exit
end

# Get the name/path of the Webiva dump file if not provided on the command line

if input_filename == "" then
  print "\nEnter the name (including path if necessary) of the Webiva dump file: "
  input_filename = gets.chop
  len = input_filename.length
#  path = path + "/" if path[len-1..len-1] != "/"
end

if !(File.exists?(input_filename))
  puts "The file " + input_filename + " does not exist - exiting!"
  exit
end

# Untar the Webiva dump file and check the validity of the restored contents 
# (it should contain a "domains" dir)

mytmpdir = Dir.mktmpdir

begin

  cmd = "(cd #{mytmpdir}; tar xf #{input_filename})"
  system(cmd)
  result=$?.success?

  if !(result) then
    puts "\nBad stuff happened while unpacking Webiva dump file - exiting!"
    exit
  end

  toplevel = `ls -1 #{mytmpdir}`
  path = mytmpdir + "/" + toplevel + "/"
  path.gsub!(/[\n]+/, "");
  puts "path: " + path if debug

  checkdomains = `/bin/ls -1d #{path}domains 2>/dev/null`.chop

  if checkdomains != "#{path}domains" then
    puts "The tar file provided does not contain a Webiva dump tree - exiting\n\n"
    exit
  end

  puts "\nTo continue, you will need the name and password of a database user with write access to the Webiva databases.\n\n"
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

  domain_info=Array.new
  domain_info[0]=Hash.new
  domain_info[0]["dbname"] = "placeholder"
  domain_info[0]["filestore"] = "placeholder"
  domain_info[0]["options"] = "placeholder"
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
    domain_info[domain_counter]["options"] = db[1]
  
  end

# Display a list of Webiva site databases to the user and see which one they
# want to overwrite with the import

  domain_counter = 1
  puts "\n\nIndex\t\tDatabase\t\t\tFilestore\n\n"
  domain_info.each do |entry|
    next if entry["dbname"] == "placeholder"
    puts domain_counter.to_s + "\t" + entry["dbname"] + "\t" + entry["filestore"]
    domain_counter += 1
  end

  print "\n\nPlease enter the index number of the Webiva db you want to replace\nwith the imported Webiva dump: "
  userindex = gets.chop.to_i

  if debug then
    puts "\n\nYou entered " + userindex.to_s
    puts "The db options for that db are: \n"
    pp domain_info[userindex]["options"]
  end

# Replace the Webiva domain.yml config file in the import tree with the YML 
# options for the domain to be overwritten

  the_domain = `/bin/ls -1 #{path}domains 2>/dev/null`.chop
  domain_restore_dir = "#{path}domains/#{the_domain}"
  domain_config_file = "#{path}domains/#{the_domain}/domain.yml"

  mv_cmd = "/bin/mv #{domain_config_file} #{domain_config_file}.save"
  system(mv_cmd)

  File.open(domain_config_file, 'w') do |fh|  
    fh.puts domain_info[userindex]["options"]
  end

# Import the Webiva dump

  cmd = "(cd #{webroot}current && rake cms:restore DOMAIN_ID=" + domain_info[userindex]["filestore"] + " DIR=" + domain_restore_dir + ")"

  puts "\nWe will run the command : '" + cmd + "'"
  print "\nIs this what you would like to do? [yN]: "
  confirm = gets.chop

  if confirm == "y" || confirm == "Y" then
    system(cmd)
    puts "\nIf there were no errors generated by the Webiva restore command, the Webiva dump has been imported."
  end

# Check with the user to see if they'd like to restart memcached (if they've
#   not already specified that via command line option

  if restart_memcached == "unset"
    restart_memcached = "y"
    print "\nDo you want to restart the memcached server to flush previously-cached data for this domain? [Yn]: "
    response = gets.chop
    restart_memcached = response if !response.empty?
  end

  if restart_memcached == "y" || restart_memcached == "Y" then
    cmd = "/sbin/service memcached restart"
    system(cmd)
  end

  puts "\n\n"

  exit

# Rescue stanzas:

# Recover from database/query errors:

  rescue DBI::DatabaseError => e
     puts "A database access error occurred:"
     puts "Error code: #{e.err}"
     puts "Error message: #{e.errstr}"
  ensure
     # disconnect from server
     dbh.disconnect if dbh
  end

# Clean up the temp directory where we were working on the restore:

ensure
  # remove the directory.
  FileUtils.remove_entry_secure mytmpdir
end

