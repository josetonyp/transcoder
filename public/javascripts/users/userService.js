window.Translator
  .service('User', ['Restangular', function(Restangular) {
    var token = "";
    return {
      login: Restangular.one("account"),
      all: Restangular.all("users")
    };
  }]);
