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

require 'net/ftp'

module Lassoweb

  module Utils

    # Class that represents a specific ruby version
    class RubyVersion

      # RubyVersion implements <=> for easy sorting
      include Comparable

      attr_reader :major, :minor, :teeny, :extra

      # Initialize a RubyVersion from a filename
      def initialize(version)
        # Work on copy
        _version = version.dup
        # Extract major version
        @major = _version[0..._version.index('.')]
        _version = _version[@major.length + 1..-1]
        # Extract minor version
        @minor = _version[0..._version.index('.')]
        _version = _version[@minor.length + 1..-1]
        # Extract teeny version
        @teeny = _version[0..._version.index('-')]
        _version = _version[@minor.length + 1..-1]
        # Check whether this is a preview version,
        # a rc version or a stable version
        if _version.start_with?('preview')
          @preview = true
          @rc = false
          @extra = _version[7..-1]
        elsif _version.start_with?('rc')
          @preview = false
          @rc = true
          @extra = _version[2..-1]
        else
          @preview = false
          @rc = false
          @extra = _version
        end
        # Convert the major, minor and teeny versions to integers
        @major = @major.to_i
        @minor = @minor.to_i
        @teeny = @teeny.to_i
      end

      # Method for comparing RubyVersions against one another
      # This makes collections of RubyVersions available for easy sorting
      def <=>(another)
        major_diff = @major <=> another.major
        return major_diff unless major_diff.zero?
        minor_diff = @minor <=> another.minor
        return minor_diff unless minor_diff.zero?
        teeny_diff = @teeny <=> another.teeny
        return teeny_diff unless teeny_diff.zero?
        unless @preview == another.preview?
          return @preview ? -1 : 1
        end
        unless @rc == another.rc?
          return @rc ? -1 : 1
        end
        return @extra <=> another.extra
      end

      # Returns string representation of this RubyVersion
      def inspect
        to_s
      end

      # Returns whether this RubyVersion is a preview release
      def preview?
        @preview
      end

      # Returns whether this RubyVersion is a release candidate
      def rc?
        @rc
      end

      # Returns string representation of this RubyVersion
      def to_s
        s = ''
        s << "#{@major}.#{@minor}.#{@teeny}-"
        s << 'preview' if @preview
        s << 'rc' if @rc
        s << "#{@extra}"
        return s
      end

    end

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

      # Class method that returns a string containing the latest stable,
      # release candidate and preview versions of the ruby interpreter
      def self.latest_ruby_versions()
        Net::FTP.open('ftp.ruby-lang.org') do |conn|
          # Logon FTP server
          conn.login
          # Change to ruby directory
          conn.chdir('/pub/ruby')
          # Calculate "latest" directory and change to it
          conn.chdir("#{max_dir(conn.list)}")
          # Calculate latest stable, rc and preview versions
          latest_stable, latest_rc, latest_preview = max_files(conn.list)
          # Return results
          "Latest stable version: #{latest_stable}\n" +
            "Latest release candidate: #{latest_rc}\n" +
            "Latest preview: #{latest_preview}"
        end
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

      private

      # Method that calculates the directory name for the "latest" ruby version
      def self.max_dir(entries)
        # Work on copy
        _entries = entries.dup
        # Reject all files
        _entries.reject! { |entry| entry[0] != 'd' }
        # Calculute directory names
        _entries.map! { |entry| entry[entry.rindex(' ') + 1..-1] }
        # Reject all directories not matching the current naming standard
        # FIXME: Does not match 1.1a, 1.1b etc. Might not be relevant though.
        _entries.reject! { |entry| entry !~ /([0-9]*\.)?[0-9]+/ }
        # Return "latest" directory name
        return _entries.max { |entry1, entry2| entry1.to_f <=> entry2.to_f }
      end

      # Method that calculates the latest ruby version from a directory listing
      def self.max_files(entries)
        # Work on copy
        _entries = entries.dup
        # Remove all directories
        _entries.reject! { |entry| entry[0] == 'd' }
        # Calculate file names
        # FIXME: How about filenames with spaces in them?
        _entries.map! { |entry| entry[entry.rindex(' ') + 1..-1] }
        # Reject all files but those ending in .bz2
        _entries.reject! { |entry| File.extname(entry) != '.bz2' }
        # Strip prefix and create a RubyVersion object from the current entry
        _entries.map! { |entry| RubyVersion.new(entry[5..-9]) }
        # Calculate latest stable version
        stable = _entries.reject { |entry| entry.preview? || entry.rc? }.max
        # Calculate latest release candidate version
        rcs = _entries.select { |entry| entry.rc? }.max
        # Calculate latest preview version
        previews = _entries.select { |entry| entry.preview? }.max
        # Return latest versions
        return stable, rcs, previews
      end

    end

  end

end