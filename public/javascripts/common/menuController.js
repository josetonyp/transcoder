window.Translator
  .controller('MenuController', ['$scope', '$route', 'Restangular', 'User', '$location', 'Satellite',
    function($scope, $route, Restangular, User, $location, Satellite) {
    $scope.user = false;

    Satellite.listen('user.available', $scope, function(event, user) {
      if (user!="null") {
        $scope.user = user;
      }
    });

    $scope.signout = function() {
      event.preventDefault();
      User.login.post("logout").then(function() {
        $scope.user = false;
        $location.path("/");
        $route.reload();
      });
      return false;
    };

  }]);
