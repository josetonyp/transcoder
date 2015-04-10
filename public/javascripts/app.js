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

.controller('AudiosController', ['$scope', 'Restangular', '$routeParams', function($scope, Restangular, params)  {
  var audio_folder = Restangular.one("audio_folders", params.id);
  audio_folder.get().then(function(folder) {
    $scope.folder = folder;
  });
}])

.directive('audioItem', [ 'Restangular', function(Restangular) {
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
        audio_file.put( {value: area.val()} ).then(function(audio) {
          scope.audio = audio;
        })
      });
    }
  };
}]);