window.Translator
  .controller('LoginController', ['$scope', 'Restangular', 'User', '$location', '$route', 'Satellite',
    function($scope, Restangular, User, $location, $route, Satellite) {
    $scope.login = {
      email: "",
      password: ""
    };
    $scope.loginSubmit= function(event) {
      User.login.post("login",$scope.login).then(function(user) {
        if (! _.isUndefined(user.email)) {
          Satellite.transmit("user.available", user);
          $location.path("/home");
          $route.reload();
        }
      });
      return false;
    };
  }]);
