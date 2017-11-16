window.Translator
  .controller('FoldersController', ['$scope', 'Folders', 'User', 'Satellite', 'currentUser', '$cookies', function($scope, Folders, User, Satellite, currentUser, $cookies) {
    $scope.currentUser = currentUser;
    $scope.taking = false;
    $scope.filterDownloaded = $cookies.get('filterDownloaded') == "downloaded";
    $scope.values = {selectedUser:  ""};

    User.all.getList({short: 1}).then(function(users) {
      $scope.select_users = users;
    });

    var findFolders = function() {
      $scope.folders =  [];
      Folders.list(currentUser, {filter: $cookies.get('filterDownloaded')}).then(function(folders) {
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
      return currentUser.admin && !$scope.taking && folder.translated == 0;
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

    $scope.toggleDowloadedFilter = function() {
      var prev = $cookies.get('filterDownloaded');
      $cookies.remove('filterDownloaded');
      if (prev == "none") {
        $cookies.put('filterDownloaded', 'downloaded');
      } else {
        $cookies.put('filterDownloaded', 'none');
      }
      $scope.filterDownloaded = $cookies.get('filterDownloaded') == "downloaded";
      findFolders();
    }

  }]);
