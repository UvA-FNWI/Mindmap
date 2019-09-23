window.fg = {}

document.addEventListener "DOMContentLoaded", (event) ->

  fg.editor = new Editor

  BaseNode::externalClickListeners = [
    fg.editor.editorLink
  ]

  fg.sidemenu = new SideMenu
  fg.mindmap = new Mindmap(() -> fg.editor.addEditStudiesButton())
  fg.panHandler = new PanHandler
  fg.clickHandler = new ClickHandler

  fg.sidemenu.startListening()
  fg.sidemenu.slideIn()
  fg.panHandler.startListening()
  fg.clickHandler.startListening()


