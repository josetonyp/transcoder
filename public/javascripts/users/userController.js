window.Translator
  .controller('UsersController', ['$scope', 'Restangular', function($scope, Restangular) {
    var users = Restangular.all("users");
    users.getList().then(function(users) {
      $scope.users = users;
    });
  }]);
