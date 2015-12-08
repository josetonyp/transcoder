window.Translator
  .controller('LoginController', ['$scope', 'Restangular', 'User', '$state', '$route', 'Satellite',
    function($scope, Restangular, User, $state, $route, Satellite) {
    $scope.login = {
      email: "",
      password: ""
    };

    $scope.loginSubmit= function(event) {
      $scope.error = "";
      User.login.post("login",$scope.login).then(function(user) {
        if (! _.isUndefined(user.email)) {
          Satellite.transmit("user.available", user);
          $state.go("home", {reload: true});
        }
      }, function(error) {
        $scope.login.password = "";
        $scope.error = error.data.error;
      });
      return false;
    };
  }]);
