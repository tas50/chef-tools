#!/usr/bin/ruby

# unused_role_check.rb: Searches for nodes in your chef server running each role in the roles
#               directory.  Prints the count of the number of nodes

require 'rubygems'
require 'trollop'

$opts = Trollop::options do
 opt :roles, "Path to the roles folder", :default => "~/chef-repo/roles"
end

# Throw an error if the path to the cookbooks folder doesn't exist
if ! File.exists?($opts[:roles])
  puts "Error: #{File.expand_path($opts[:roles])} does not exist."
  puts "Please provide a valid path the roles directory with the \"-r\" flag"
  exit 1
end

# get an array of all local repository roles
def get_roles()
  roles = Array.new
  Dir.foreach($opts[:roles]) do |role|
    if !role.start_with?(".") and (role.end_with?(".rb") or role.end_with?(".json"))
      roles << role.split('.')[0]
    end
  end
  return roles
end

# get the array of all cookbooks
roles = get_roles()

roles.each do |role|
  result = `knife search node role:#{role} | grep items`
  puts "#{role}: #{result}"
end