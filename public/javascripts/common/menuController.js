window.Translator
  .controller('MenuController', ['$scope', '$state', 'Satellite', 'currentUser', function($scope, $state, Satellite, currentUser) {
    $scope.currentUser = currentUser;
    $scope.folders_count = "";
    Satellite.listen('folders.loaded', $scope, function(_, folders) {
      $scope.folders_count = '(' + folders.length + ')'
    })
    $scope.signout = function() {
      event.preventDefault();
      User.login.post("logout").then(function() {
        $scope.user = false;
        $state.go("login", {reload: true});
      });
    };
  }]);
