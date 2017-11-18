window.Translator
  .controller('MenuController', ['$scope', '$state', 'Satellite', 'currentUser', 'User', function($scope, $state, Satellite, currentUser, User) {
    $scope.currentUser = currentUser;
    $scope.folders_count = "";

    Satellite.listen('folders.loaded', $scope, function(_, count) {
      $scope.folders_count = '(' + count + ')'
    });

    var reloadUser = function() {
      User.login.get().then(function(user) {
        $scope.currentUser = user;
        Satellite.transmit('user.reloaded', user);
      });
    }

    Satellite.listen('audio.updated', $scope, reloadUser);
    Satellite.listen('audio.reviewed', $scope, reloadUser);

    $scope.signout = function() {
      event.preventDefault();
      User.login.post("logout").then(function() {
        $scope.user = false;
        $state.go("login", {reload: true});
      });
    };
  }]);
