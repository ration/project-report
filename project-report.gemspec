Gem::Specification.new do |s|
  s.name = "project-report"
  s.version = "0.0.1"
  s.summary = "Generate language statistics and dependency report for projects"
  s.description = "Generate language statistics and dependency report for projects.
Shows used languages with row counts, used package managers and dependenccies."
  s.authors = ["Tatu Lahtela"]
  s.email = "lahtela@iki.fi"
  s.files = ["bin/project-report"]
  s.homepage = "https://github.com/ration/project-report"
  s.license = "MIT"
  s.add_runtime_dependency "github-linguist", ["= 7.16.0"]
  s.add_runtime_dependency "bibliothecary", ["= 7.0.2"]
  s.executables = ["project-report"]
end
