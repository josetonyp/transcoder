window.Translator
  .service('Invoice', ['Restangular', function(Restangular) {
    var token = "";
    return {
      all: Restangular.all("api/invoices"),
      find: function (id) {
        return Restangular.one("api/invoices", id).get();
      }
    };
  }]).controller('InvoicesController', ['$scope', 'Invoice', function($scope, Invoice) {
    $scope.invoices = [];
    Invoice.all.getList().then(function(invoices) {
      $scope.invoices = invoices;
    });
  }])
  .controller('InvoiceController', ['$scope', 'Invoice', '$stateParams', "$state", function($scope, Invoice, stateParams, state) {
    Invoice.find(stateParams.id).then(function(invoice) {
      $scope.invoice = invoice;
    });
  }]);
