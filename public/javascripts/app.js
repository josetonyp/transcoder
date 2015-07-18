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
    users: Restangular.all("users")
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

.controller('AppController', ['$scope', '$location', 'User', 'Restangular', function($scope, $location, User,Restangular) {
  $scope.user = false;

  $scope.isHome = function() {
    return $location.path() == '/home';
  };

  User.login.get().then(function(user) {
    if (user!="null") {
      $scope.user = user;
    };
  });

  Restangular.all("audio_folders").getList().then(function(folders) {
    $scope.folders = folders;
    // _.sortBy(folders,function(folder) {
    //   return ( folder.responsable ) ? folder.responsable.id : folder.responsable;
    // });
  });

}])

.controller('MenuController', ['$scope', '$route', 'Restangular', 'User', '$location', 'Satellite',
  function($scope, $route, Restangular, User, $location, Satellite) {
  $scope.user = false;

  User.login.get().then(function(user) {
    if (user!="null") {
      $scope.user = user;
    };
  })

  $scope.signout = function() {
    event.preventDefault();
    User.login.post("logout").then(function() {
      $scope.user = false;
      $location.path("/");
      $route.reload();
    })
    return false;
  };

  Satellite.listen("user_loggin", $scope, function() {
    User.login.get().then(function(user) {
      if (user!="null") {
        $scope.user = user;
      };
    })
  });

}])

.controller('HomeController', ['$scope', 'Restangular', function($scope, Restangular) {
  $scope.taking = false;

  $scope.take = function(folder) {
    $scope.taking = true;
    Restangular.one("audio_folders", folder.id).put({}).then(function(newFolders) {
        $scope.$parent.folders = newFolders
        // _.sortBy(newFolders,function(folder) {
        //   return ( folder.responsable ) ? folder.responsable.id : folder.responsable;
        // });
      $scope.taking = false;
    });
  };
  $scope.notResponsable = function(folder) {
    return !folder.hasResponsable && !$scope.taking;
  }
  $scope.folderReady = function(folder) {
    return folder.status == 'ready';
  };

  $scope.folderIsMine = function(folder) {
    if ( $scope.$parent.user.admin ) {
      return true;
    }
    if ( _.isNull(folder.responsable) ) {
      return true;
    }
    return $scope.$parent.user.id == folder.responsable.id ;
  }

}])
.controller('UsersController', ['$scope', 'Restangular', function($scope, Restangular) {
  var users = Restangular.all("users")
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
    User.login.post("login",$scope.login).then(function(data) {
      if ( ! _.isUndefined( data.email ) ) {
        Satellite.transmit("user_loggin")
        $location.path("/home");
        $route.reload();
      };
    });
    return false;
  };
}])

.controller('AudiosController', ['$scope', '$location', 'Restangular', '$routeParams','Satellite', '$route', function($scope,$location, Restangular, params, Satellite, $route)  {
  $scope.review = $route.current.data.review;

  var audio_folder = Restangular.one("audio_folders", params.id);
  if( _.isUndefined( params.page ) ){
    var page = 1
  }else{
    var page = parseInt(params.page);
  }
  $scope.current_page = page;

  audio_folder.get( {page: page }).then(function(folder) {
    $scope.folder = folder;
    $scope.pages = _.range(folder.pages);
  });
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
              case 12: //f
                return " [f]";
              case 13: //m
                return " [m]";
              case 3: //c
                return "\\contact ";
              case 10: // j
                return "\\mp: ";
              case 21: //u
                return "\\noise:unintelligeble ";
              case 9: // i
                return "\\i:";
              case 18: // r
                audio[0].play();
                return "";
              case 23: // w
                return "[bad wave]";
              case 44: // , comma
                return "\\comma\\";
              case 46: // . period
                return "\\period\\";
              case 7: // g
                return "\\noise:bgspeech";
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
