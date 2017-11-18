window.Translator
  .service('Folders', ['Restangular', function(Restangular) {
    var filterToUser = _.curry(function(user, folders) {
      return _(folders).filter(function(folder) {
        return user.admin || ( !_.isNull(folder.responsable) && folder.responsable.id == user.id );
      }).value();
    });
    return {
      list: function(user, options) {
        if (_.isUndefined(options)) {
          options = {};
        }
        return Restangular.all("api/audio_folders").getList(options).then(filterToUser(user));
      },
      take: function(admin, folder, user_id) {
        return Restangular.one("api/audio_folders", folder.id).put({user_id: user_id}).then(filterToUser(admin));
      },
      get: function(folder_id, options) {
        return Restangular.one("api/audio_folders", folder_id).get(options);
      },
      processFiles: function(folder_id) {
        return Restangular.one("api/audio_folders", folder_id).one('process_files').get();
      }
    };
  }]);
