window.Translator
  .controller('AudiosController', ['$scope', '$state', 'Folders','Satellite', '$stateParams', 'currentUser',
    function($scope,$state, Folders, Satellite, $stateParams, currentUser)  {
    $scope.currentUser = currentUser;
    var findAudios = function(page) {
      Folders.get($stateParams.id, {page: page }).then(function(folder) {
        if ( !currentUser.admin && (_.isNull(folder.responsable) || folder.responsable.id != currentUser.id) ){
          $state.go('home');
        }
        $scope.folder = folder;
        $scope.pages = _.range(folder.pages);
      });
    };

    $scope.review = $state.current.data.review;

    var page = 1;

    if(!_.isUndefined($stateParams.page)) {
      page = parseInt($stateParams.page);
    }

    $scope.current_page = page;

    findAudios(page);

    $scope.nextPage = function(){
      if (page < $scope.folder.pages)
        $state.go( "folders", { id: $stateParams.id , page: page + 1} );
    };
    $scope.prevPage = function(){
      if (page > 1)
        $state.go( "folders", { id: $stateParams.id , page: page - 1} );
    };

    Satellite.listen("next_page", $scope, function() {
      $scope.nextPage();
    });
  }]);
