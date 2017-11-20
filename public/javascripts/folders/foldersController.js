window.Translator
  .controller('FoldersController', ['$scope', 'Folders', 'User', 'Satellite', 'currentUser', '$cookies',  '$stateParams', "$state", function($scope, Folders, User, Satellite, currentUser, $cookies, $stateParams, $state) {
    $scope.currentUser = currentUser;
    $scope.taking = false;
    $scope.foolderStatus = $cookies.get('foolderStatus');
    $scope.values = {selectedUser:  ""};

    var page = 1;

    if(!_.isUndefined($stateParams.page)) {
      page = parseInt($stateParams.page);
    }

    $scope.current_page = page;

    User.all.getList({short: 1}).then(function(users) {
      $scope.select_users = users;
    });

    $scope.findFolders = function() {
      $scope.folders =  [];
      Folders.list(currentUser, {page: $scope.current_page, filter: $cookies.get('foolderStatus')}).then(function(xhr) {
        $scope.foldersResponse = xhr;
        $scope.folders = xhr.folders;
        $scope.pages = _.range(xhr.pages);
        Satellite.transmit('folders.loaded', xhr.total);
        return xhr.folders;
      });
    };

    $scope.findFolders();


    $scope.selectUser = function(folder) {
      $scope.take(folder, $scope.values.selectedUser);
    };

    $scope.take = function(folder, user_id) {
      $scope.taking = true;
      Folders.take(currentUser, folder, user_id).then(function(folders) {
        $scope.findFolders();
        $scope.taking = false;
        $scope.values.selectedUser = "";
      });
    };

    $scope.notResponsable = function(folder) {
      return currentUser.admin && !$scope.taking && folder.translated == 0;
    }

    $scope.folderReady = function(folder) {
      return (folder.status == 'reviewed' || folder.status == "downloaded");
    };

    $scope.folderIsMine = function(folder) {
      if ( currentUser.admin ) {
        return true;
      }
      if (_.isUndefined(folder.responsable)) {
        return true;
      }
      return currentUser.id == folder.responsable.id ;
    }

    var toggleFilter = function(name, value) {
      var prev = $cookies.get(name);
      $cookies.remove(name);
      $cookies.put(name, value);
    }

    $scope.toggleFilter = function(name) {
      toggleFilter('foolderStatus', name);
      $scope.foolderStatus = $cookies.get('foolderStatus');
      $scope.findFolders()
    }

    $scope.getFolderStatus = function(name) {
      return $cookies.get('foolderStatus') == name;
    }

    $scope.processFiles = function(folder_id) {
      Folders.processFiles(folder_id).then(function(folder) {
        $scope.findFolders();
      });
    }

    $scope.nextPage = function(){
      if (page < $scope.foldersResponse.pages)
        $state.go( "home", { page: page + 1} );
    };

    $scope.prevPage = function(){
      if (page > 1)
        $state.go( "home", { page: page - 1} );
    };

  }]);
