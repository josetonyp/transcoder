window.Translator
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
  }]);
