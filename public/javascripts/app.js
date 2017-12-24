'use strict';
// Declare app level module which depends on views, and components
window.Translator
  .config(['$urlRouterProvider', '$stateProvider', '$locationProvider', function($urlRouterProvider, $stateProvider, $locationProvider) {

    $urlRouterProvider.otherwise("/home");
    if(window.history && window.history.pushState){
      $locationProvider.html5Mode(true);
    }

    $stateProvider
      .state('app', {
        abstract: true,
        templateUrl: '/views/layout.html',
        controller: 'MenuController',
        resolve: {
          currentUser: function(User, $state, Satellite) {
            return User.login.get().then(function(user) {
              return user
            }, function(error) {
              if (error.status == 404){
                $state.go('login');
              }
            });
          }
        }
      })
      .state('home', {
        url: '/home?page',
        parent: 'app',
        templateUrl: '/views/home.html',
        controller: 'FoldersController'
      })
      .state('folders', {
        url: '/folder/:id?page',
        parent: 'app',
        templateUrl: '/views/audios.html',
        controller: 'AudiosController',
        data: {
          review: false
        }
      })
      .state('folders_review', {
        url: '/folder_review/:id?page',
        parent: 'app',
        templateUrl: '/views/audios.html',
        controller: 'AudiosController',
        data: {
          review: true
        }
      })
      .state('users', {
        url: '/users',
        parent: 'app',
        templateUrl: '/views/users.html',
        controller: 'UsersController'
      })

      .state('user', {
        url: '/users/:id',
        parent: 'app',
        templateUrl: '/views/user.html',
        controller: 'UserController'
      })

      .state('layout', {
        abstract: true,
        templateUrl: '/views/layout.html',
      })
      .state('login', {
        url: '/login',
        parent: 'layout',
        templateUrl: '/views/login.html',
        controller: 'LoginController'
      });
  }]);
