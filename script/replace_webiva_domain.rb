#!/usr/bin/env ruby 

# replace_webiva_domain.rb - Proceduralize backing up and replacing a Webiva 
#                            domain with a dump from a site on another Webiva 
#                            server using the task tools 
#                            "import_webiva_domain.rb" and 
#                            "export_webiva_domain.rb".

def usage()
   puts "\nUsage: replace_webiva_domain [-d -f import_file -h -v]\n\n"
   puts "\t -d \t\tEnable debug output"
   puts "\t -f \t\tName of import file [include path if necessary]"
   puts "\t -h \t\tPrint usage summary"
   puts "\t -m \t\tRestart memcached after importing domain"
   puts "\t -o \t\tName of backup file for domain being replaced [include path if necessary]"
   puts "\t -v \t\tEnable verbose output"
   puts "\nEnvironment options:\n\n"
   puts "\t -p \t\tForce environment to production"
   puts "\t -b \t\tForce environment to beta"
   puts "\t -s \t\tForce environment to staging"
   puts "\n(The environment default is to allow the subsidiary domain import and export "
   puts "commands to set their own defaults, ie. production on host shiitake, beta"
   puts "on otter, staging on tussey.)\n\n"
   exit
end

# Get command line options, initialize variables

backupfileopt = ""
backup_filename = ""
debugopt = ""
environopt = ""
fileopt = ""
input_filename = ""
memcached_opt = ""
verboseopt = ""

while ARGV.length > 0 do
   case ARGV[0].to_s
      when "-b" then 
         environopt = "-b"
      when "-d" then 
         debugopt = "-d"
      when "-f" then 
         fileopt = "-f"
         ARGV.shift
         input_filename = ARGV[0]
      when "-h" then 
         usage
      when "-m" then 
         memcached_opt = "-m"
      when "-o" then 
         backupfileopt = "-f"
         ARGV.shift
         backup_filename = ARGV[0]
      when "-p" then 
         environopt = "-p"
      when "-s" then 
         environopt = "-s"
      when "-v" then 
         verboseopt = "-v"
   end
   ARGV.shift
end

backup_cmd = "export_webiva_domain.rb #{environopt} #{debugopt} #{verboseopt} #{backupfileopt} #{backup_filename}"
import_cmd = "import_webiva_domain.rb #{fileopt} #{input_filename} #{environopt} #{debugopt} #{verboseopt} #{memcached_opt}"

backup_cmd = backup_cmd.gsub(/\s+/, ' ')
import_cmd = import_cmd.gsub(/\s+/, ' ')

puts "\nRunning #{backup_cmd} to back up domain before replacing it."
print "Proceed?: "
answer = gets.chop
if answer == "y" || answer == "Y" then
  system(backup_cmd)
else
  exit
end

puts "\nRunning #{import_cmd} to replace domain."
print "Proceed?: "
answer = gets.chop
if answer == "y" || answer == "Y" then
  system(import_cmd)
else
  exit
end
