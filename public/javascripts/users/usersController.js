window.Translator
  .controller('UsersController', ['$scope', 'User', function($scope, User) {
    $scope.users = [];
    User.all.getList().then(function(users) {
      $scope.users = users;
    });
  }])
  .controller('UserController', ['$scope', 'User', '$stateParams', "$state", function($scope, User, stateParams, state) {
    User.find(stateParams.id).then(function(folders) {
      $scope.folders = folders;
    });
  }]);
