window.Translator
  .controller('FoldersController', ['$scope', 'Folders', 'User', 'Satellite', 'currentUser', function($scope, Folders, User, Satellite, currentUser) {
    $scope.currentUser = currentUser;
    $scope.taking = false;
    $scope.values = {selectedUser:  ""};

    User.all.getList({short: 1}).then(function(users) {
      $scope.select_users = users;
    });

    var findFolders = function() {
      Folders.list(currentUser).then(function(folders) {
        $scope.folders = folders;
        Satellite.transmit('folders.loaded', folders);
        return folders;
      });
    };
    findFolders();


    $scope.selectUser = function(folder) {
      $scope.take(folder, $scope.values.selectedUser);
    };

    $scope.take = function(folder, user_id) {
      $scope.taking = true;
      Folders.take(currentUser, folder, user_id).then(function(folders) {
        $scope.folders = folders;
        $scope.taking = false;
        $scope.values.selectedUser = "";
      });
    };
    $scope.notResponsable = function(folder) {
      return currentUser.admin && !folder.hasResponsable && !$scope.taking;
    }

    $scope.folderReady = function(folder) {
      return folder.status == 'ready';
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

  }]);
