window.Translator
  .service('Folders', ['Restangular', function(Restangular) {
    return {
      list: function(user, options) {
        if (_.isUndefined(options)) {
          options = {};
        }
        return Restangular.one("api/audio_folders").get(options);
      },
      take: function(admin, folder, user_id) {
        return Restangular.one("api/audio_folders", folder.id).put({user_id: user_id});
      },
      get: function(folder_id, options) {
        return Restangular.one("api/audio_folders", folder_id).get(options);
      },
      processFiles: function(folder_id) {
        return Restangular.one("api/audio_folders", folder_id).one('process_files').get();
      }
    };
  }]);
