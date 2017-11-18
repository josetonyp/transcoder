window.Translator
  .controller('FoldersController', ['$scope', 'Folders', 'User', 'Satellite', 'currentUser', '$cookies', function($scope, Folders, User, Satellite, currentUser, $cookies) {
    $scope.currentUser = currentUser;
    $scope.taking = false;
    $scope.foolderStatus = $cookies.get('foolderStatus');
    $scope.values = {selectedUser:  ""};

    User.all.getList({short: 1}).then(function(users) {
      $scope.select_users = users;
    });

    $scope.findFolders = function() {
      $scope.folders =  [];
      Folders.list(currentUser, {filter: $cookies.get('foolderStatus')}).then(function(folders) {
        $scope.folders = folders;
        Satellite.transmit('folders.loaded', folders);
        return folders;
      });
    };

    $scope.findFolders();


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
      return folder.status == 'reviewed';
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

  }]);
