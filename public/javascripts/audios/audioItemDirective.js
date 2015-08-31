window.Translator
  .directive('audioItem', [ 'Restangular', 'Satellite', function(Restangular, Satellite) {
    return {
      restrict: 'C',
      link: function(scope, element, attrs) {
        var audio = element.find("audio");
        var area = element.find("textarea");
        var checkbox = element.find("checkbox");

        area.on("keypress", function(event) {
          if (event.ctrlKey && (event.which != 63234 || event.which != 63235) ){
            var text = (function() {
              switch (event.which) {
                // case 12: //f
                //   return " [f]";
                // case 13: //m
                //   return " [m]";
                case 3: //c
                  return "\\contact";
                case 99: //c
                  return "\\contact";

                case 10: // j
                  return "\\pf:";
                case 106: // j
                  return "\\pf:";

                case 21: //u
                  return "\\u";
                case 117: //u
                  return "\\u";
                // case 9: // i
                //   return "\\i:";
                case 18: // r
                  audio[0].play();
                  return "";
                case 114: // r
                  audio[0].play();
                  return "";
                case 23: // w
                  return "[BAD]";
                case 119: // w
                  return "[BAD]";
                // case 44: // , comma
                //   return "\\comma\\";
                // case 46: // . period
                //   return "\\period\\";
                case 7: // g
                  return "[BG]";
                case 103: // g
                  return "[BG]";
                default:
                  return "";
              }
            })();

            $(this).insertAtCursor(text);
            return false;
          }
        });

        area.on("focusin", function(event) {
          audio[0].play();
        });

        area.on("focusout", function(event) {
          var audio_file = Restangular.one("audio_files", element.attr("id"));

          var  total_audios = $("textarea", element.parents(".all_audios")).length ;
          audio_file.put( {value: area.val()} ).then(function(audio) {
            scope.audio = audio;
            if(scope.review){
              audio_file.put({ review: true }).then(function(audio) { scope.audio = audio; });
            }
            if (area.attr("tabindex") == total_audios &&  audio.status != "new"){
              Satellite.transmit("next_page");
            }
          });
        });

      }
    };
  }]);
