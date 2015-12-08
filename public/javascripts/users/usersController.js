window.Translator
  .controller('UsersController', ['$scope', 'User', function($scope, User) {
    User.all.getList().then(function(users) {
      $scope.users = users;
    });
  }]);
