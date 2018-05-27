module Users
  module Serialisable
    def to_h
      translated = audio_folders.inject(0){|t,folder| t + folder.audio_files.translated.count }
      total = audio_folders.inject(0){|t,folder| t + folder.audio_files.count }
      folders =
      {
        id: id.to_s,
        name: name,
        admin: admin,
        email: email,
        token: token,
        folders: audio_folders.for_user(self).count(),
        payrol: ""
      }
    end

    def min_json
      {
        id: id.to_s,
        name: name,
        admin: admin
      }
    end

    def to_json
      to_h.to_json
    end
  end
end
