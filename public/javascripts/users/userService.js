window.Translator
  .service('User', ['Restangular', function(Restangular) {
    var token = "";
    return {
      login: Restangular.one("api/account"),
      all: Restangular.all("api/users"),
      find: function (id) {
        return Restangular.one("api/users", id).get();
      },
      folders: function (id) {
        return Restangular.one("api/users", id).getList('folders');
      }
    };
  }]);
