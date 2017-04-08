;(function($) {
    $.fn.selectPlugin = function(){
        var start = 1000;
        var finish = 1;
        var list = [];
        while (start >= finish){
          list.push(start);
          start -= 1;
        }
        function pageSelected(){
          console.log( $("#select-input").prop('value') )
        }
        function find(arr, v){
          var i = 0;
          while ( (""+arr[i]).indexOf(v) ==-1  &&  i<arr.length){  i += 1  }
          return i
        } 

        var $selectInput = $(this);
        $selectInput.addClass("select-input");
        
        function setText(page){
          $selectInput.prop('value',page);
        }
        
        var width = $selectInput.prop("clientWidth");
        
        $("body").append(
          "<div id='select-drop-down' class='drop-down-menu'>" + 
          list.reduce( function(r,x){ return r + "<span>" + x + "</span>" }, "" ) + "</div>" + 
          "<div id='guesser' class='guesser'></div>"
        );
        
        var $dropDown = $("#select-drop-down");
        var $guesser = $("#guesser");

        $dropDown[0].style.width =  width+'px';
        $dropDown[0].style.top =  $selectInput.position().top + $selectInput.prop("scrollHeight") + 4 + 'px';
        $dropDown[0].style.position = 'absolute'
        
        $guesser[0].style.width =  width - 30 +'px';
        $guesser[0].style.top =  $selectInput.position().top + $selectInput.prop("scrollHeight") + 4 + 'px';
        $guesser[0].style.left =  $selectInput.position().left + 10 + 'px';
        $guesser[0].style.position = 'absolute'
        
        $selectInput.on("focus", function(e){
            $dropDown.show();
            $dropDown.children().show();
        })
        $selectInput.on("keypress", function(e){
            if (event.which == 13 || event.keyCode == 13) {
                $dropDown.hide();
                pageSelected();
                return false;
            } else { return true }
        })
        
        $selectInput.on("keyup", function(e){
          var index = find( list, $selectInput.prop('value') );
          
          if (list[index]){
            $guesser.html( list[index] );
            $guesser.show();
          }
        })
        
        $dropDown.on("click", function(e){
            var $span = $(e.target).closest("span");
            if ($span.length>0){
                setText($span.text())
            }
            pageSelected();
            $dropDown.hide();
            $guesser.hide();
        })
        $dropDown.on("mouseover", function(e){
            $selectInput[0].onblur = null
        })
        $dropDown.on("mouseleave", function(e){
            $selectInput[0].onblur = function(e){
                $dropDown.hide();
                $guesser.hide();
            }
        })
        $dropDown.on("blur", function(e){
            $dropDown.hide();
            $guesser.hide();
        })
        
        $dropDown.hide();
        
        $guesser.on("click", function(){
          console.log(123);
          /*var text = $(this).text();
          setText( text );
          pageSelected();*/
          $dropDown.hide();
          $guesser.hide();
        })

        return this;
    };
})(jQuery);