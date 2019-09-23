window.fg = {}

document.addEventListener "DOMContentLoaded", (event) ->
  fg.mindmap = new Mindmap
  fg.panHandler = new PanHandler
  fg.clickHandler = new ClickHandler

  fg.panHandler.startListening()
  fg.clickHandler.startListening()

