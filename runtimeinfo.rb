=begin

Copyright (C) 2010 Lars Olsson (lasso@lassoweb.se)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

module Lassoweb

  module Utils

    class RuntimeInfo

      # Class method that provides the same information as `gem -v`
      def self.gem_version()
        Gem::RubyGemsVersion
      end

      # Class method that provides the same information as `gem list`
      def self.installed_gems()
        # Create a hash that will return an empty array whenever a key is
        # accessed for the first time
        installed_gems = Hash.new { |hash, key| hash[key] = [] }
        # Iterate over local gem specs
        Gem.source_index.each do |spec|
          # Add current spec to the list of installed gems
          # If the spec represents a different version of a gem
          # that has already been added, just add the version
          installed_gems[spec.last.name].push(spec.last.version)
        end
        # Sort versions in descending order and join the name and version(s)
        # of each spec. Finally, join all specs to a single string
        installed_gems.collect do |gem|
          "#{gem.first} (#{gem.last.sort { |v1, v2| v2 <=> v1 }.collect { |version| version.version }.join(', ')})"
        end.join($/)
      end

      # Class method that provides the same information as `gem outdated`
      def self.outdated_gems()
        # Create an empty hash that will hold data on all outdated gems
        outdated_gems = Hash.new
        # Iterate over outdated gems
        Gem.source_index.outdated.each do |gem|
          # Get latest local spec for gem
          latest_local_spec =
            Gem.source_index.search(Gem::Dependency.new(gem)).max { |v1, v2| v1.version <=> v2.version}
          # Get latest remote spec for gem
          latest_remote_spec = Gem::SpecFetcher.fetcher.fetch(Gem::Dependency.new(gem, ">#{latest_local_spec.version.version}")).collect { |spec| spec.first }.max { |v1, v2| v1.version <=> v2.version}
          # Store latest local and remote versions
          outdated_gems[gem] = [latest_local_spec.version.version, latest_remote_spec.version.version]
        end
        # Join the name and versions for each outdated gem. Finally, join all outdated gems to a single string
        outdated_gems.collect do |gem|
          "#{gem.first} (#{gem.last.join(' < ')})"
        end.join($/)
      end

      # Class method that provides the same information as `ruby -v`
      def self.ruby_version()
        "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE} revision #{RUBY_REVISION}) [#{RUBY_PLATFORM}]"
      end

    end

  end

end