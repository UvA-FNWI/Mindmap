// Generated by CoffeeScript 1.12.7
(function() {
  window.fg = {};

  document.addEventListener("DOMContentLoaded", function(event) {
    fg.mindmap = new Mindmap;
    fg.panHandler = new PanHandler;
    fg.clickHandler = new ClickHandler;
    fg.panHandler.startListening();
    return fg.clickHandler.startListening();
  });

}).call(this);
