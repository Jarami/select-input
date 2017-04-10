## AUTOBUILD_PRAGMA deferred
User::Module.modify :UTH_WebContainer_Monitoring do

  methods planner_data: <<'  METHOD'
    # $TfsSource:  $
    def self.planner_data(params)

      planner_manager = User::UTH_Module_PlannerManager.instance
      planners = {
        "ur_tps_yearly" => { planner: planner_manager.get_UR_TPS_Yearly, period: "yearly" },
        "ur_tps_quarterly" => { planner: planner_manager.get_UR_TPS_Quarterly, period: "quarterly" },
        "ur_tps_monthly" => { planner: planner_manager.get_UR_TPS_Monthly, period: "monthly" },
        "ur_tps_decade" => { planner: planner_manager.get_UR_TPS_Decade, period: "decade" },
        "ur_tps_daily" => { planner: planner_manager.get_UR_TPS_Daily, period: "daily" },
        "kzo_tps_yearly_first" => { planner: planner_manager.get_KZO_TPS_Yearly_First, period: "yearly" },
        "kzo_tps_yearly_second" => { planner: planner_manager.get_KZO_TPS_Yearly_Second, period: "yearly" },
        "kzo_tps_quarterly" => { planner: planner_manager.get_KZO_TPS_Quarterly, period: "quarterly" },
        "kzo_tps_monthly" => { planner: planner_manager.get_KZO_TPS_Monthly, period: "monthly" },
        "kzo_lb_yearly" => { planner: planner_manager.get_KZO_LB_Yearly, period: "yearly" },
        "kzo_lb_quarterly" => { planner: planner_manager.get_KZO_LB_Quarterly, period: "quarterly" },
        "kzo_lb_monthly" => { planner: planner_manager.get_KZO_LB_Monthly, period: "monthly" }
      }
      #planners.default = { planner: User::UTH_Module_PlannerManager.instance.get_UR_TPS_Daily, period: "daily" }

      if params["planner"] && params["action"]
        # послан ajax-запрос => вернуть json
        @params['request'].setContentType('application/json')
        @params['request'].set_character_encoding('utf-8')

        begin 
          planner = planners[params["planner"]][:planner]
          time = params['time'] || User::UTH_Time.now
          time = Time.at(time.to_i)
    
          h = User::UTH_ORM_Handlers.get(:Отчеты)

          case params["action"]
            when "show" then 
              r = h.получить_последний_отчет(planner, time)
              return { success: true, action: "show", input: r[:input_data][0..19], output: r[:output_data][0..19], planned_time: r[:planned_time]}.to_json
            when "download" then
              r = h.получить_последний_отчет_архив(planner, time)
              return { success: true, action: "download", input: r[:input_data], output: r[:output_data], planned_time: r[:planned_time]}.to_json
            else 
              return { success: false, message: "Неизвестное значение параметра 'action'." }.to_json		
          end
        rescue => error
          return { success: false, message: error.message }.to_json
        end
      else
        # первый запрос => вернуть html
        html = %`<!doctype html>
<html>
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <script type="text/javascript" language="javascript" src="/data/Plugin/external/jquery/jquery-1.10.2.min.js"></script>
    <script type="text/javascript" language="javascript" src="/data/Plugin/jquery-ui.js"></script>
    <link type="text/css" rel="stylesheet" href="/data/Plugin/jquery-ui.css">
    <script type="text/javascript" src="/data/Plugin/Daterangepicker/daterangepicker.init.js"></script>
    <link type="text/css" rel="stylesheet" href="/data/Plugin/Daterangepicker/daterangepicker.css">
  
    <script>
      var plannerData = { input: [], output: [] }

      // загрузчик файла
      var downloader = {
        download: function(data, name){
          var fileNameToSaveAs = name;
          if (window.Blob) {
              var textFileAsBlob = new Blob([data], { type: 'text/plain' });
              var downloadLink = document.createElement("a");
              downloadLink.download = fileNameToSaveAs;
              downloadLink.innerHTML = "Download File";
              if (window.webkitURL != null) {
                  downloadLink.href = window.webkitURL.createObjectURL(textFileAsBlob);
              } else {
                  downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
                  downloadLink.onclick = this.destroyClickedElement;
                  downloadLink.style.display = "none";
                  document.body.appendChild(downloadLink);
              }
              if (navigator.msSaveBlob) {
                  navigator.msSaveBlob(textFileAsBlob, fileNameToSaveAs);
              } else {  downloadLink.click();  }
          } else if (document.execCommand) {
              var oWin = window.open();
              oWin.document.writeln(tab_text);
              oWin.document.close();
              var success = oWin.document.execCommand('SaveAs', true, "file.txt")
              oWin.close();
          }
        },
        destroyClickedElement: function(event){  document.body.removeChild(event.target);  }
      }
            
      function AjaxHandler(){
        
        var observers = []; // сюда пушатся модели
        this.register = function(observer){ observers.push(observer) };
        function notify(){  for(var i in observers){ observers[i].update() } }
        
        function makeURL(params){
        //"&time=" + params.time +
          return "planner_data?planner=" + params.planner +  "&action=" + params.action
        }
        this.send = function(params){
          var url = makeURL(params)
          $.ajax({
              url: url,
              dataType: 'json',
              cache: false,
          })
          .done(function( data ){  
              console.log( "ajax succes" )
              if (data.success) {
                   console.log( "ajax data succes" )
                   if (data.action=="show") { 
                      plannerData.input = data.input;
                      plannerData.output = data.output;
                      notify();
                   } else if (data.action=="download"){
                      console.log(data);
                      downloader.download(data.input, "input.zlib");
                      downloader.download(data.output, "output.zlib");
                   } else {
                      console.log(data);
                   }
              } else {
                  console.log(data);
              }
          })
          .fail( function(e) {  console.log( e )  })
          .always( function() {  console.log( 'Вызов завершен' )  });
        }
      }
      
      function Controller(){
        var model = undefined; // модель - объект стратегии для контроллера
        this.setModel = function(_model){  model = _model  }
        this.goToNextPage = function(){  this.goToPage( model.getPage() + 1 )  }
        this.goToPreviousPage = function(){  this.goToPage( model.getPage() - 1 )  }
        this.goToPage = function(page){  model.setPage(page)  }
        this.filter = function( filterString ){  model.filter(filterString)  }
        this.update = function(){}
      }
      function View(){
          var controller = undefined; // контроллер - объект стратегии для представления
          var model = undefined; // модель - объект стратегии для представления
          this.setController = function(_controller){  controller = _controller  }
          this.setModel = function(_model){  model = _model  }
          
          var $pageSelector = undefined;
          var $info = undefined;
          var $filter = undefined;
          var $filterInput = undefined;
          var $output = undefined;
          
          this.init = function(){
          
              $pageSelector = $("#output-data-page-selector");
              $info = $("#output-info");
              $filter = $("#output-data-filter");
              $filterInput = $("#output-data-filter-input");
              $output = $("#output-data");
              
              $filter.click( filterClicked )
              
              $filterInput.keypress( function(e){
                  if (e.which == 13 || e.keyCode == 13) { // "Enter" на поле фильтра
                      $filter.click();
                  } else { return true }
              })
        
              $(".paginate-button").click( function(){
                  pageClicked( $(this).attr('data-page') )  
              })
              
              $pageSelector.change( function(){
                  pageClicked( this.value )
              })
              $(".page-navigation a").mousedown( function(){
                    $(this).addClass("mousedown");
              });
              $(document).mouseup( function(){
                    $(".page-navigation a").removeClass("mousedown");
              });
          }
          // обработка пользовательских действий
          function pageClicked(page){
              if (page == "next"){ controller.goToNextPage()  }
              else if (page == "back"){  controller.goToPreviousPage()  }
              else {  controller.goToPage(+page)  }
          }
          function filterClicked(){
              controller.filter(  $filterInput.prop('value')  );
          }
          // наблюдатель
          this.update = function(){ 
              updatePageSelector();
              updateOutput();
              updateInfo();
          }
          function updatePageSelector(){
            var page = model.getPage();
            var options = "";
            var ipage = 1;
            while (ipage <= model.MAXPAGE){
              options += "<option value="+ipage+">"+ipage+"</option>";
              ipage += 1;
            }
            $pageSelector.html(options);
            $pageSelector.prop('value', page);
          }
          function updateOutput(){
              var records = model.getSelectedRecords();
              var page = model.getPage();
              var outputHTML = records.map( function(value){ return value+"<br/>"} );
              $output.html(outputHTML);
          }          
          function updateInfo(page){
              var page = model.getPage();
              var firstRecordAtPage = model.getStartSelectedRecordNumber();
              var lastRecordAtPage = model.getLastSelectedRecordNumber();
              var recordsNumber = model.getRecordsNumber();
              var originalRecordNumber = model.getOriginalRecordsNumber();
              
              $info.html(" строки "+firstRecordAtPage+" - "+lastRecordAtPage+" из "+recordsNumber+" ("+originalRecordNumber+")" );
          }
      }
      
      function Model(_dataType){
        
          var recordPerPage = 50;
          var dataType = _dataType;
          var records = [];
          var recordsFiltered = records;
          var recordsAtPage = [];
          
          this.MINPAGE = undefined;
          this.MAXPAGE = undefined;
          var page = this.MINPAGE;

          // регистрация и оповещение наблюдателей
          var observers = [];
          this.register = function(observer){ observers.push(observer) };
          this.notify = function(){  for (var i in observers){ observers[i].update() }  }

          // модель как наблюдатель
          this.update = function(){
            records = plannerData[dataType];
            recordsFiltered = records;
            this.MINPAGE = 1;
            this.MAXPAGE = Math.ceil( recordsFiltered.length / recordPerPage );
            this.MAXPAGE = this.MAXPAGE==0 ? 1 : this.MAXPAGE;
            page = this.MINPAGE;
            this.setPage(1);
            this.notify();
          }
          
          this.setPage = function(_page){
              if (_page>=this.MINPAGE && _page <= this.MAXPAGE ){
                  page = _page;
                  
                  var startIndex = (page-1)*recordPerPage;
                  var finishIndex = Math.min(page*recordPerPage, recordsFiltered.length);
                  
                  recordsAtPage = recordsFiltered.slice(startIndex,finishIndex)
                  this.notify();
              }
          }
          this.getPage = function(){ return page }
          this.getSelectedRecords = function(){ return recordsAtPage }
          this.getStartSelectedRecordNumber = function(){ return Math.min((page-1)*recordPerPage+1, recordsFiltered.length) }
          this.getLastSelectedRecordNumber = function(){ return Math.min(page*recordPerPage, recordsFiltered.length) }
          this.getRecordsNumber = function(){ return recordsFiltered.length }
          this.getOriginalRecordsNumber = function(){ return records.length }
          
          this.filter = function(filterString){
          
              if (filterString == ""){
                recordsFiltered = records 
              } else {
                recordsFiltered = records.filter( function(value){ return ~(value.indexOf(filterString)) } );
              }
              this.MINPAGE = 1;
              this.MAXPAGE = Math.ceil( recordsFiltered.length / recordPerPage );
              this.MAXPAGE = this.MAXPAGE==0 ? 1 : this.MAXPAGE;
              this.setPage(1);
          }
      }
      
      $( function(){
          var modelInput = new Model("input");
          var modelOutput = new Model("output");
          
          var controller = new Controller();
          controller.setModel(modelInput);
          
          var view = new View();
          view.setController(controller);
          view.setModel(modelInput);
          view.init();
          
          modelInput.register(view);
          modelInput.register(controller);
          
          modelOutput.register(view);
          modelOutput.register(controller);
          
          modelInput.update();
          modelOutput.update();

          var ajaxHandler = new AjaxHandler();
          ajaxHandler.register(modelInput);
          ajaxHandler.register(modelOutput);
          
          var datepicker = $("#period-selector").daterangepicker({startDate: new Date(#{ User::UTH_Time.now.to_i * 1000 }) });
          
          $(".planner-selection").click( function(e){
                var dataAction = $(e.target).attr("data-action");
                if (dataAction){
                    var plannerSelector = document.getElementById("planner-selector");
                    console.log( plannerSelector.value );
                    console.log( plannerSelector.options[ plannerSelector.selectedIndex ].getAttribute("data-period") )
                    console.log(dataAction)
                    ajaxHandler.send({ planner: plannerSelector.value, action: dataAction})
                    if (dataAction=="download") $("#download-info").toggle(200);

                }
          })

          $("#planner-selector").change( function(e){
                switch (this.options[ this.selectedIndex ].getAttribute("data-period")){
                  case "yearly": datepicker.selectYear(); break;
                  case "quarterly": datepicker.selectQuarter(); break;
                  case "monthly": datepicker.selectMonth(); break;
                  case "daily": datepicker.selectDay(); break;
                  default: break;
                }
          });
          
          $(".data-selection").click( function(e){
                var modelCurrent = undefined;
                var $target = $(e.target);
                if ($target){
                  var dataType = $target.attr("data-type");
                  if (dataType){
                      switch (dataType){
                          case "input": modelCurrent = modelInput; break;
                          case "output": modelCurrent = modelOutput; break;
                      }
                      controller.setModel(modelCurrent);
                      view.setModel(modelCurrent);
                      modelCurrent.notify();
                      $(".data-selection").children().removeClass("selected");
                      $target.toggleClass("selected");
                  }
                }
          })

      })
    </script>
    <style>    
      .controls > * {
        height: 30px;
        box-sizing: border-box;
        margin: 0 5px;
      }    
      .controls a{
        display: inline-block;
        cursor: pointer;
        width: 30px; 
        border: 1px solid rgb(169,169,169);
        border-radius: 3px;
        text-indent: -99999px;
      }
      .controls a.mousedown{
        border-color: rgb(101,135,190);
        box-shadow: 0 0 1px 1px rgba(101,135,190,1);
      }

      .controls a span.icon-triangle-left{  background: url('/data/Plugin/images/ui-icons_0073ea_256x240.png') -95px -14px no-repeat;  }
      .controls a span.icon-triangle-right{  background: url('/data/Plugin/images/ui-icons_0073ea_256x240.png') -31px -14px no-repeat;  }
      .controls a span.icon-search{  background: url('/data/Plugin/images/ui-icons_0073ea_256x240.png') -159px -110px no-repeat;  }

      .controls a:not(.mousedown) span.icon-triangle-left{  background: url('/data/Plugin/images/ui-icons_666666_256x240.png') -95px -15px no-repeat;  }
      .controls a:not(.mousedown) span.icon-triangle-right{  background: url('/data/Plugin/images/ui-icons_666666_256x240.png') -31px -15px no-repeat;  }
      .controls a:not(.mousedown) span.icon-search{  background: url('/data/Plugin/images/ui-icons_666666_256x240.png') -159px -111px no-repeat;  }
      
      .controls .input{
          min-width: 75px;
          border: 1px solid rgb(169,169,169);
          border-radius: 2px;
      }
      .controls .input:focus{
          border-color: rgb(101,135,190);
          box-shadow: 0 0 1px 1px rgba(101,135,190,1);
      }
      .controls input{
        padding: 5px 5px;
        margin: 0 5px 0 0;
      }
      
      .info{
        font-family: "Comic Sans MS", cursive, sans-serif;
        display: block-inline;
        width: 300px;
      }
      
      .output {
        overflow: scroll;
        margin: 5px;
        padding: 15px;
      }
      
      .page-navigation > *:not(#output-data-filter-input) {
         -moz-user-select: -moz-none;
         -khtml-user-select: none;
         -webkit-user-select: none;
         -ms-user-select: none;
         user-select: none;
      }
      
      .data-selection > *{
        width: 200px; height: 30px;
        display: inline-block;
        border: 1px solid black;
        margin: auto;
        text-align: center;
        padding: 5px;
        cursor: pointer;
        background-color: white;
      }
      .data-selection > *.selected{
        border-bottom: 1px solid white;
      }
      #download-info{
        display: none;
        position:absolute; 
        width:650px; 
        margin:5px;padding:5px;
        left: 25%; top: 0; 
        border: 1px solid #CCC;
        border-radius: 5px;
        background-color: #EEE;
        font: 10pt Verdana, Geneva, sans-serif;
        opacity:0.3;
      }
      #download-info:hover{  opacity: 0.8;  }
      
      .icon{
        display: block;
        cursor: pointer;
        width: 16px; height: 16px;
        margin: 4px;
      }
      .icon-close {
        background: url('/data/Plugin/images/ui-icons_666666_256x240.png') -96px -128px no-repeat;
        border: 1px solid transparent;
      }
      .icon-close:hover {  border-color: #CCC;  }
      
      .ui-daterangepicker-prev{ 
          position: relative; 
          display: block;
          width: 25px !important; height: 25px;
          border: 1px solid transparent !important;
          padding: 0em;
          top: 0.03em;
      }
      .ui-daterangepicker-next{
          position: relative;
          display: block;
          width: 25px  ; height: 25px;
          border: 1px solid transparent !important;
          padding: 0em;
          top: 0.03em;
      }
      .daterangepicker-widget-container{
          box-sizing:border-box;
          height: 30px;
          display: block;
          border: 1px solid grey;
          position: relative;
          width: 15em;
          padding: 0em;
          
      }
      .daterangepicker-title{
          position: relative;
          width: 200px;
          margin: 0.1em auto; padding: 0.1em;
          top: 0.1em;
          text-align: center;
          display: block;
      }

      .daterangepicker-input{ 
        box-sizing:border-box;
        border: 1px solid grey;
        padding: 0 !important;
        margin: 0 !important;
        width: 15em;
        height: 30px;
      }
    </style>
  </head>
  
  <body>
    <div class="planner-selection controls" style="display:inline-block;">
      <select id="planner-selector" class="input" style="float:left;">` + planners.map{|plannerValue, planner| %`
        <option value=#{plannerValue} data-period=#{planner[:period]}>` + planner[:planner].get_name + %`</option>`}.join + %`
      </select>
      <div id="period-selector" style="float:left;display:block;"></div>
      <button data-action="show" style="float:left;">Показать</button>
      <button data-action="download" style="float:left;">Загрузить</button>
    </div>
    <div class="data-selection controls" style="display:block;margin: -1px 5px;">
      <div data-type='input' class="selected">Входные данные</div>
      <div data-type='output'>Выходные данные</div>
    </div>
    <div style="border: 1px solid black; padding: 5px 0;">
      <div class="page-navigation controls">
        <a class="paginate-button" data-page="back"><span class="icon-triangle-left icon">back</span></a>
        <select id="output-data-page-selector" class="input"></select>
        <a class="paginate-button" data-page="next"><span class="icon-triangle-right icon">next</span></a>
        <span id="output-info" class="info"></span>
        <input id="output-data-filter-input" type="textarea" class="input" style="float:right;display: inline-block;" />
        <a id="output-data-filter" style="float:right;" ><span class="icon-search icon">filter</span></a>
      </div>
      <pre id="output-data" class="output"></pre>
    </div>
    
    <div id="download-info">
      <div style="float:left;">
      unzip_data =->(data){ Marshal.load(Zlib::Inflate.inflate(data.to_s.unpack("u*").first)) }<br/>
      c = File.open('C:/path/to/your/file.zlib','r'){|f| f.read}<br/>
      r = unzip_data.call(c)
      </div>
      <a style="float:right;text-indent: -99999px;" style="display:inline-block;">
        <span onclick="$('#download-info').toggle();" class="icon-close icon" >close</span>
      </a>
    </div>
  </body>
</html>`
      end
    end
  METHOD
end
