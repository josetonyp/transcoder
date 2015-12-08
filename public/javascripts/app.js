'use strict';
// Declare app level module which depends on views, and components
window.Translator
  .config(['$urlRouterProvider', '$stateProvider', '$locationProvider', function($urlRouterProvider, $stateProvider, $locationProvider) {
    $urlRouterProvider.otherwise("/login");
    if(window.history && window.history.pushState){
      $locationProvider.html5Mode(true);
    }
    $stateProvider
    .state('home', {
      url: '/home',
      templateUrl: '/views/home.html',
      controller: 'FoldersController'
        })
    .state('folders', {
      url: '/folder/:id?page',
      templateUrl: '/views/audios.html',
      controller: 'AudiosController',
      data: {
        review: false
      }
    })
    .state('folders_review', {
      url: '/folder_review/:id?page',
      templateUrl: '/views/audios.html',
      controller: 'AudiosController',
      data: {
        review: true
      }
    })
    .state('users', {
      url: '/users',
      templateUrl: '/views/users.html',
      controller: 'UsersController'
        })
    .state('login', {
      url: '/login',
      templateUrl: '/views/login.html',
      controller: 'LoginController'
        });
  }])

  .run(['$rootScope', '$state', 'User', "Satellite", function($rootScope, $state, User, Satellite) {
    $rootScope.$on("$routeChangeStart", function(args){
      User.login.get().then(function(data) {
        if ( data == "null" ) {
          $state.go("login");
        }

        Satellite.transmit("user_loggin");
      });
    });
  }]);
