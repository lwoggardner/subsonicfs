require 'rfusefs'
require 'json'
require 'set'
require 'rest-client'
require 'pathname'

module SubsonicFS
    class Playlists < FuseFS::FuseDir

        attr_reader :playlists
        def initialize(url)
            @url = url
            @playlists = {}
        end

        def directory?(path)
            split_path(path) do |base,rest|
                if base.nil? || base == ""
                    true
                elsif playlists.has_key?(base)
                   playlists[base].directory?(rest)
                end
            end
        end

        def times(path)
            super
        end

        def file?(path)
            split_path(path) { |base,rest| playlists[base].file?(rest) if playlists.has_key?(base) }
        end

        def contents(path)
            puts "Hello #{path}"
            if path == "/" || path == ""
               playlists.keys
            else
               split_path(path) { |base,rest| playlists[base].contents(rest) }
            end
        end

        def read_file(path)
            split_path(path) { |base,rest| playlists[base].read_file(rest) }
        end

        def size(path)
            split_path(path) { |base,rest| playlists[base].size(rest) }
        end

        def mounted
            refresh()
        end

        def sighup
            refresh()
        end

        private
        def refresh()
            # subsoncics api is not very restful, but oh well
            new_playlists = {}
            pl_json = RestClient.get("#{@url}/rest/getPlaylists.view",{ :params => { :v => "1.10.2", :f => "json", :c => "RubSonicFS" } })
            result = JSON.parse(pl_json)
            result["subsonic-response"]["playlists"]["playlist"].each do |playlist|
                name = playlist["name"]
                id = playlist["id"]
                new_playlists[name] = Playlist.new(@url,id)
            end
            @playlists = new_playlists
            @playlists.each_value { |p| p.mounted }
            puts "Found #{@playlists.size} playlists"
        end

        def split_path(path)
            base,rest = super
            return yield base,rest if block_given?
            [base,rest]
        end


    end

    class Playlist < FuseFS::FuseDir

        # Hash of media items by path
        attr_reader :files

        # Hash by path containing Sets of paths
        attr_reader :folder_content

        def initialize(url,id)
            @url = url
            @playlist_id = id
            @files = {}
            @folder_content = {}
        end

        def directory?(path)
            return true if path.nil? || path == "/" || path == ""

            folder_content.has_key?(path)
        end

        def file?(path)
            files.has_key?(path)
        end

        def contents(path)
            path = "/" if path.nil? || path == ""
            folder_content[path].to_a.sort
        end

        def size(path)
            files[path]["size"]
        end

        def read_file(path)
            download(path)
        end

        def mounted
            STDOUT.sync
            puts "Mounted"
            refresh
        end

        def sighup
            refresh
        end

        private

        def refresh
            puts "Refreshing"
            # for each entry... add folder content for the path
            new_files = {}
            new_folder_content = Hash.new() { |h,k| h[k] = Set.new() }
            pl_json = RestClient.get("#{@url}/rest/getPlaylist.view",{ :params => { :v => "1.10.2", :f => "json", :c => "SubSonicFS", :id => @playlist_id } })
            result = JSON.parse(pl_json)
            result["subsonic-response"]["playlist"]["entry"].each do |entry|
                path = Pathname("/#{entry["path"]}")
                new_files[path.to_path] = entry
                while true
                    parent = path.dirname
                    new_folder_content[parent.to_path] << path.basename.to_path
                    break if parent.to_path == "/"
                    path = parent
                end
            end
            @files = new_files
            @folder_content = new_folder_content
            puts "Found #{@files.size} files"
            true
        end

        def download(path)
            file_id = files[path]["id"]
            RestClient.get("#{@url}/rest/download.view",{ :params => { :v => "1.10.2", :c => "SubSonicFS", :id => file_id } })
        end
    end
end
