#!/usr/bin/env ruby
require 'rugged'
require 'linguist'
require 'optparse'
require 'bibliothecary'

def parse_options
  ARGV.push('-h') if ARGV.empty?
  options = { :name => "",
              :business => "",
  }
  OptionParser.new do |opts|
    opts.banner = "Generate statistics about project, such as used languages, row counts and dependencies.
  Usage: project-report.rb [options] -r<paths to git repository in local directory>

  Example: ./project-report.rb -r . -n\"Project Report\" --business=\"Open Source\"

  Options:
"

    opts.on("-oFILE", "--output-file=FILE", "Write output to this file. Otherwise to STDOUT") do |o|
      options[:output] = o
    end
    opts.on("-nNAME", "--project-name=NAME", "Project name, will be prompted if not set") do |name|
      options[:name] = name
    end
    opts.on("-bBUSINESS", "--business=BUSINESS", "Project business area, will be prompted if not set") do |business|
      options[:business] = business
    end
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
    opts.on("-rX,Y,Z --repos=X,Y,Z", Array, "Comma separated list of repository paths to scan. All repositories are assumed to be under the same project") do |list|
      options[:repos] = list
      options[:repos].each do |repo|
        raise "#{repo} must be a git directory" unless File.directory?("#{repo}/.git")
      end
    end
  end.parse!

  mandatory = [:repos]
  missing = mandatory.select { |param| options[param].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', ')) #
  end

  options
end

def language_stats(path)
  repo = Rugged::Repository.new(path)
  Linguist::Repository.new(repo, repo.head.target_id)
end

# Scan Package manager data
def scan_package_manager_data(root, paths)
  manifests = Bibliothecary.identify_manifests(paths)
  project_analyses = manifests.flat_map do |manifest|
    Bibliothecary.analyse_file("#{root}/#{manifest}", File.open("#{root}/#{manifest}").read)
  end
  project_analyses.filter do |analysis|
    # TODO flag for lockfile data? Drop them for now
    analysis[:kind] != "lockfile"
  end
end

def repo_stats(repo_path)
  stats = language_stats(repo_path)
  files = stats.repository.index.map { |h| h[:path] }
  scans = scan_package_manager_data(repo_path, files)
  {
    "path" => repo_path,
    "languages" => stats.languages,
    "subprojects" => scans.map { |scan|
      {
        "platform" => scan[:platform],
        "path" => scan[:path],
        "dependencies" => scan[:dependencies].map { |dep|
          {
            "name" => dep[:name],
            "type" => dep[:type].to_s,
            "requirement" => dep[:requirement]
          }
        }
      }
    }
  }
end

# Prompt missing fields
options = parse_options
if options[:name] == ""
  print "Project name? "
  options[:name] = STDIN.gets.strip
end
if options[:business] == ""
  print "Project business area (e.g. ecommerce, banking, etc..)? "
  options[:business] = STDIN.gets.strip
end

# Generate end result
project = {
  "project" => {
    "name" => options[:name],
    "business" => options[:business],
    "repos" => options[:repos].map{ |repo| repo_stats(repo)}
  }
}
if options[:output]
  File.write(options[:output], project.to_yaml)
else
  puts(project.to_yaml(indentation: 10))
end
