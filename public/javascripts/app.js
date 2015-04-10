'use strict';


// Declare app level module which depends on views, and components
var Translator = angular.module('Translator', [
  'ngRoute',
  'restangular'
]).
config(['$routeProvider', function($routeProvider) {
  $routeProvider
  .when('/home', {
    templateUrl: '/views/home.html',
    controller: 'HomeController'
      })
  .when('/folder/:id', {
    templateUrl: '/views/audios.html',
    controller: 'AudiosController'
      })
  .otherwise({redirectTo: '/home'});
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
.controller('MenuController', ['$scope', 'Restangular', function($scope, Restangular) {
  var audio_folders = Restangular.all("audio_folders");
  audio_folders.getList().then(function(folders) {
    $scope.folders = folders;
  });
}])

.controller('HomeController', ['$scope', 'Restangular', function($scope, Restangular) {
  var audio_folders = Restangular.all("audio_folders");
  audio_folders.getList().then(function(folders) {
    $scope.folders = folders;
  });
}])

.controller('AudiosController', ['$scope', '$location', 'Restangular', '$routeParams','Satellite', function($scope,$location, Restangular, params, Satellite)  {
  var audio_folder = Restangular.one("audio_folders", params.id);
  if( _.isUndefined( params.page ) ){
    var page = 1
  }else{
    var page = parseInt(params.page);
  }
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
                return "<intruder> </intruder>";
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
          if (area.attr("tabindex") == total_audios &&  audio.status != "new"){
            Satellite.transmit("next_page");
          }
        });
      });
    }
  };
}]);