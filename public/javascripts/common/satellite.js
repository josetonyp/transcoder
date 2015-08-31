window.Translator
  .factory('Satellite', function($rootScope) {
    var msgBus;
    msgBus = {};
    msgBus.transmit = function(msg, value) {
      return $rootScope.$emit(msg, value);
    };
    msgBus.listen = function(msg, scope, func) {
      var unbind;
      unbind = $rootScope.$on(msg, func);
      return scope.$on('$destroy', unbind);
    };
    return msgBus;
  });
