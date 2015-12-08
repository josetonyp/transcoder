window.Translator
  .controller('UsersController', ['$scope', 'User', function($scope, User) {
    $scope.users = [];
    User.all.getList().then(function(users) {
      $scope.users = users;
    });
  }]);
