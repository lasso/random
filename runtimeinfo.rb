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
        gem_list = []
        Gem.source_index.each do |spec|
          gem_list << "#{spec.last.name} (#{spec.last.version.version})"
        end
        gem_list.join($/)
      end

      # Class method that provides the same information as `ruby -v`
      def self.ruby_version()
        "#{RUBY_ENGINE} #{RUBY_VERSION}p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE} revision #{RUBY_REVISION}) [#{RUBY_PLATFORM}]"
      end

    end

  end

end