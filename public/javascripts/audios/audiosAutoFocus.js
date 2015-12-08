window.Translator
  .directive('autofocus', ['$timeout', function($timeout) {
    return {
      restrict: 'A',
      link : function(scope, element) {
        $timeout(function() {
          element.find("textarea:first").focus();
        }, 350);
      }
    }
  }]);
