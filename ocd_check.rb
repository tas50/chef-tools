#!/usr/bin/ruby

# ocd_check.rb: Obsessive Cookbook Disorder Check: Simple script to check the cookbooks in your 
#               local repo against the versions on the Opscode community site.  It will return 
#               false positives if your cookbooks have the same name as community cookbook site 
#               cookbooks.

require 'net/http'
require 'rubygems'
require 'json'
require 'trollop'

$opts = Trollop::options do
 opt :repo, "Path to the cookbooks folder", :default => "~/chef-repo/cookbooks"
end

# lookup a single community cookbook site cookbook version
def cb_remote_lookup(cb_name)
  url = "http://cookbooks.opscode.com/api/v1/cookbooks/#{cb_name}"
  resp = Net::HTTP.get_response(URI.parse(url))

  if resp.code == "404"
    return nil
  else
    par_resp = JSON.parse(resp.body)
    version = par_resp["latest_version"].split('/').last.gsub!('_', '.')
    return version
  end
end

# Throw an error if the path to the cookbooks folder doesn't exist
if ! File.exists?($opts[:repo])
  puts "Error: #{File.expand_path($opts[:repo])} does not exist."
  puts "Please provide a valid path the cookbooks directory with the \"-r\" flag"
  exit 1
end

# get an array of all local repository cookbooks
def get_cookbooks()
  cookbooks = Array.new
  Dir.foreach($opts[:repo]) do |cookbook_dir|
    if File.directory?(File.join($opts[:repo],cookbook_dir)) and !cookbook_dir.start_with?(".")
      cookbooks << cookbook_dir
    end
  end
  return cookbooks
end

# lookup a single local cookbooks version
def cb_local_lookup(cb_name)
  full_path = File.expand_path("#{$opts[:repo]}/#{cb_name}")
  version = (`grep '^version' #{full_path}/metadata.rb`)
  return version.split(' ').last.gsub('"','').gsub('\'','').chomp
end

# get the array of all cookbooks
cookbooks = get_cookbooks()

cookbooks.each do |cb|
  remote = cb_remote_lookup(cb)
  if remote == nil
    puts cb + " not found on the cookbook site"
  else
    local = cb_local_lookup(cb)
    if local != remote
      puts cb + " version mismatch: Local: #{local} Cookbook site: #{remote}"
    else
      puts cb + " version up to date"
    end
  end
end