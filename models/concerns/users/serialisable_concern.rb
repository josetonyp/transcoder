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
        folders: {
          count: audio_folders.count(),
          started: audio_folders.started.count(),
          translated: audio_folders.translated.count(),
          reviewed: audio_folders.reviewed.count(),
          downloaded: audio_folders.downloaded.count(),
          delivered: audio_folders.delivered.count(),
          paid: audio_folders.paid.count(),
          archived: audio_folders.archived.count(),
        }
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
