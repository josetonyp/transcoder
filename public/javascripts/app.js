'use strict';
// Declare app level module which depends on views, and components
window.Translator
  .config(['$routeProvider', function($routeProvider) {
    $routeProvider
    .when('/home', {
      templateUrl: '/views/home.html',
      controller: 'HomeController'
        })
    .when('/folder/:id', {
      templateUrl: '/views/audios.html',
      controller: 'AudiosController',
      data: {
        review: false
      }
    })
    .when('/folder_review/:id', {
      templateUrl: '/views/audios.html',
      controller: 'AudiosController',
      data: {
        review: true
      }
    })
    .when('/users', {
      templateUrl: '/views/users.html',
      controller: 'UsersController'
        })
    .when('/login', {
      templateUrl: '/views/login.html',
      controller: 'LoginController'
        })
    .otherwise({redirectTo: '/login'});
  }])


  .controller('HomeController', ['$scope', 'Folders', 'User', 'Satellite', function($scope, Folders, User, Satellite) {
    $scope.taking = false;
    $scope.values = {selectedUser:  ""};

    User.all.getList({short: 1}).then(function(users) {
      $scope.select_users = users;
    });

    var findFolders = function() {
      Folders.list($scope.$parent.user).then(function(folders) {
        $scope.folders = folders;
      });
    };

    if ($scope.$parent.user) {
        findFolders();
    } else {
      Satellite.listen('user.available', $scope, function(event, user) {
        findFolders();
      });
    }

    $scope.selectUser = function(folder) {
      $scope.take(folder, $scope.values.selectedUser);
    };

    $scope.take = function(folder, user_id) {
      $scope.taking = true;
      Folders.take($scope.$parent.user, folder, user_id).then(function(folders) {
        $scope.folders = folders;
        $scope.taking = false;
      });
    };
    $scope.notResponsable = function(folder) {
      return $scope.$parent.user.admin && !folder.hasResponsable && !$scope.taking;
    }

    $scope.folderReady = function(folder) {
      return folder.status == 'ready';
    };

    $scope.folderIsMine = function(folder) {
      if ( $scope.$parent.user.admin ) {
        return true;
      }
      if (_.isUndefined(folder.responsable)) {
        return true;
      }
      return $scope.$parent.user.id == folder.responsable.id ;
    }

  }])


  .run(['$rootScope', '$location', 'User', "Satellite", function($rootScope, $location, User, Satellite) {
    $rootScope.$on("$routeChangeStart", function(args){
      User.login.get().then(function(data) {
        if ( data == "null" ) {
          $location.path("/login");
        };
        Satellite.transmit("user_loggin");
      })
    })
  }]);
