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
        $scope.folderInfo = folder;
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

    var actionName = function(review) {
      var action = "";
      if (review) {
        action = "folders_review";
      } else {
        action = "folders";
      }

      return action;
    }

    $scope.nextPage = function(review){
      if (page < $scope.folder.pages)
        $state.go( actionName(review), { id: $stateParams.id , page: page + 1} );
    };
    $scope.prevPage = function(review){
      if (page > 1)
        $state.go( actionName(review), { id: $stateParams.id , page: page - 1} );
    };

    Satellite.listen("next_page", $scope, function(event, review) {
      $scope.nextPage(review);
    });

    $scope.setFolderReviewed = function(folderInfo) {
      Folders.setReviewed(folderInfo.id).then(function(folder) {
        $scope.folderInfo = folder;
      });
    }


    var reloadFolderInfo = function() {
      Folders.get($stateParams.id, {page: page }).then(function(folder) {
        $scope.folderInfo = folder;
      });
    }

    Satellite.listen('audio.updated', $scope, reloadFolderInfo);
    Satellite.listen('audio.reviewed', $scope, reloadFolderInfo);

  }]);
