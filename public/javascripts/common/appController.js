window.Translator
  // Controller in HTML
  .controller('AppController', ['$scope', '$location', 'User', 'Satellite', 'Folders', function($scope, $location, User, Satellite, Folders) {
    $scope.user = false;

    $scope.isHome = function() {
      return $location.path() == '/home';
    };

    User.login.get().then(function(user) {
      if (user!="null") {
        $scope.user = user;
        Satellite.transmit("user.available", user);
      }
    });

    Satellite.listen('user.available', $scope, function(event, user) {
      Folders.list(user).then(function(folders) {
        $scope.folders_count = folders.length;
      });
    });
  }]);
