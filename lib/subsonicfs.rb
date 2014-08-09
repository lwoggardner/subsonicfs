require "subsonicfs/version"
require 'subsonicfs/filesystem'

module SubsonicFS

    def self.main(*args)

        FuseFS.main(args,nil,nil,"http://<user>:<pass>@<your subsonic server>") do |options|
            Playlists.new(options[:device])
        end
    end
end
