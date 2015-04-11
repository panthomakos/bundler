module Bundler
  class Fetcher::CompactGemList
    class Cache
      attr_reader :directory

      def initialize(directory)
        @directory = p Pathname(directory).expand_path
        FileUtils.mkdir_p dependencies_path(nil)
      end

      def names
        lines(names_path)
      end

      def names_path
        directory + 'names'
      end

      def versions
        versions_by_name = {}
        lines(versions_path).map do |line|
          next if line == '-1'
          name, versions_string = line.split(" ", 2)
          p line unless versions_string
          versions_string.split(",").map! do |version|
            version.split("-", 2).unshift(name)
          end
        end
        versions_by_name
      end

      def versions_path
        directory + 'versions'
      end

      def dependencies(name)
        lines(dependencies_path(name)).map do |line|
          parse_gem(line)
        end
      end

      def dependencies_path(name)
        directory + 'dependencies' + name.to_s
      end

      def specific_dependency(name, version, platform)
        pattern = [version, platform].compact!.join("-")
        matcher = %r{\A#{Regexp.escape(pattern)} } unless pattern.empty?
        lines(dependencies_path(name)).each do |line|
          return parse_gem(line) if line =~ matcher
        end if matcher
        nil
      end

      def versions_length
        versions_path.file? ? versions_path.size : 0
      end

      def versions_hash
        versions_path.file? ? Digest::MD5.file(versions_path).hexdigest : 0
      end

      private

      def lines(path)
        return [] unless path.file?
        lines = path.read.lines
        header = lines.index("---\n")
        lines = header ? lines[header+1..-1] : lines
        lines.map!(&:strip!)
      end

      def parse_gem(string)
        version_and_platform, rest = string.split(" ", 2)
        version, platform = version_and_platform.split("-", 2)
        dependencies, requirements = rest.split("|", 2).map { |s| s.split(",") } if rest
        dependencies = dependencies ? dependencies.map { |d| parse_dependency(d) } : []
        requirements = requirements ? requirements.map { |r| parse_dependency(r) } : []
        [version, platform, dependencies, requirements]
      end

      def parse_dependency(string)
        dependency = string.split(":")
        dependency[-1] = dependency[-1].split("&")
        dependency
      end
    end
  end
end