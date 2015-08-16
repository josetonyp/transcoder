'use strict';
// Declare app level module which depends on views, and components
var Translator = angular.module('Translator', [
  'ngRoute',
  'restangular'
])
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
.service('User', ['Restangular', function(Restangular) {
  var token = "";
  return {
    login: Restangular.one("account"),
    all: Restangular.all("users")
  };
}])
.service('Folders', ['Restangular', function(Restangular) {
  var filterToUser = _.curry(function(user, folders) {
    return _(folders).filter(function(folder) {
      return user.admin || ( !_.isNull(folder.responsable) && folder.responsable.id == user.id );
    }).value();
  });
  return {
    list: function(user, options) {
      if (_.isUndefined(options)) {
        options = {};
      }
      return Restangular.all("audio_folders").getList(options).then(filterToUser(user));
    },
    take: function(admin, folder, user_id) {
      return Restangular.one("audio_folders", folder.id).put({user_id: user_id}).then(filterToUser(admin));
    },
    get: function(folder_id, options) {
      return Restangular.one("audio_folders", folder_id).get(options);
    }
  };
}])
.factory('Satellite', function($rootScope) {
  var msgBus;
  msgBus = {};
  msgBus.transmit = function(msg, value) {
    return $rootScope.$emit(msg, value);
  };
  msgBus.listen = function(msg, scope, func) {
    var unbind;
    unbind = $rootScope.$on(msg, func);
    return scope.$on('$destroy', unbind);
  };
  return msgBus;
})

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
}])

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
.controller('UsersController', ['$scope', 'Restangular', function($scope, Restangular) {
  var users = Restangular.all("users");
  users.getList().then(function(users) {
    $scope.users = users;
  });
}])
.controller('LoginController', ['$scope', 'Restangular', 'User', '$location', '$route', 'Satellite',
  function($scope, Restangular, User, $location, $route, Satellite) {
  $scope.login = {
    email: "",
    password: ""
  };
  $scope.loginSubmit= function(event) {
    User.login.post("login",$scope.login).then(function(user) {
      if (! _.isUndefined(user.email)) {
        Satellite.transmit("user.available", user);
        $location.path("/home");
        $route.reload();
      }
    });
    return false;
  };
}])

.controller('AudiosController', ['$scope', '$location', 'Folders', '$routeParams','Satellite', '$route',
  function($scope,$location, Folders, params, Satellite, $route)  {
  var findAudios = function() {
    Folders.get(params.id, {page: page }).then(function(folder) {
      if ( !$scope.$parent.user.admin && (_.isNull(folder.responsable) || folder.responsable.id != $scope.$parent.user.id) ){
        $location.path('/home');
      }
      $scope.folder = folder;
      $scope.pages = _.range(folder.pages);
    });
  }
  $scope.review = $route.current.data.review;

  if( _.isUndefined( params.page ) ){
    var page = 1;
  }else{
    var page = parseInt(params.page);
  }
  $scope.current_page = page;

  if ($scope.$parent.user) {
    findAudios();
  } else {
    Satellite.listen('user.available', $scope, function(event, user) {
      findAudios();
    });
  }

  $scope.nextPage = function(){
    if (page < $scope.folder.pages)
      $location.search( "page", page + 1 );
  };
  $scope.prevPage = function(){
    if (page > 1)
      $location.search( "page", page - 1 );
  };

  Satellite.listen("next_page", $scope, function() {
    $scope.nextPage();
  });
}])



.directive('audioItem', [ 'Restangular', 'Satellite', function(Restangular, Satellite) {
  return {
    restrict: 'C',
    link: function(scope, element, attrs) {
      var audio = element.find("audio");
      var area = element.find("textarea");
      var checkbox = element.find("checkbox");

      area.on("keypress", function(event) {
        if (event.ctrlKey && (event.which != 63234 || event.which != 63235) ){
          var text = (function() {
            switch (event.which) {
              // case 12: //f
              //   return " [f]";
              // case 13: //m
              //   return " [m]";
              case 3: //c
                return "\\contact";
              case 10: // j
                return "\\pf:";
              case 21: //u
                return "\\u";
              // case 9: // i
              //   return "\\i:";
              case 18: // r
                audio[0].play();
                return "";
              case 23: // w
                return "[BAD]";
              // case 44: // , comma
              //   return "\\comma\\";
              // case 46: // . period
              //   return "\\period\\";
              case 7: // g
                return "[BG]";
              default:
                return "";
            }
          })();

          $(this).insertAtCursor(text);
          return false;
        }
      });

      area.on("focusin", function(event) {
        audio[0].play();
      });

      area.on("focusout", function(event) {
        var audio_file = Restangular.one("audio_files", element.attr("id"));

        var  total_audios = $("textarea", element.parents(".all_audios")).length ;
        audio_file.put( {value: area.val()} ).then(function(audio) {
          scope.audio = audio;
          if(scope.review){
            audio_file.put({ review: true }).then(function(audio) { scope.audio = audio; });
          }
          if (area.attr("tabindex") == total_audios &&  audio.status != "new"){
            Satellite.transmit("next_page");
          }
        });
      });

    }
  };
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
