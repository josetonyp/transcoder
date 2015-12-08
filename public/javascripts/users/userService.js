window.Translator
  .service('User', ['Restangular', function(Restangular) {
    var token = "";
    return {
      login: Restangular.one("api/account"),
      all: Restangular.all("api/users")
    };
  }]);
