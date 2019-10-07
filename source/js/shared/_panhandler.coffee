# Provides a simple interface to enable the dragging
# and panning of the mindmap content.
class PanHandler

  # Initializes the variables used to keep track
  # of the movement.
  constructor: () ->
    @listening = false
    @dragging = false
    @previousMouseX = @previousMouseY = 0
    @content = document.getElementById "content"
    @mindmap = document.getElementById "mindmap"

  # Starts listening for pan events.
  startListening: () ->
    @listening = true
    @bindMouseDown()
    @bindMouseUp()
    @bindTouchDown()
    @bindTouchUp()
    @bindMouseMove()
    @bindTouchMove()

  # Binds the mousedown handler so we know when
  # the dragging starts.
  bindMouseDown: () ->
    @content.addEventListener "mousedown", (event) =>
      overlay = document.getElementById "overlay"
      if @listening and !recursiveHasClass(event.target, "no-drag") and event.target != overlay  and !isDescendant(event.target, overlay)
        event.preventDefault()
        @dragging = true
        @previousMouseX = event.clientX
        @previousMouseY = event.clientY
        document.body.style.cursor = "move"

  # Binds the mouseup handler so we know when
  # the dragging ends.
  bindMouseUp: () ->
    @content.addEventListener "mouseup", (event) =>
      @dragging = false
      event.preventDefault()
      document.body.style.cursor = "default"

  # Binds the touchdown handler so we know when
  # the dragging starts.
  bindTouchDown: () ->
    @content.addEventListener "touchstart", (event) =>
      if @listening and !recursiveHasClass(event.target, "no-drag")
        event.preventDefault()
        @dragging = true
        @previousMouseX = event.targetTouches[0].pageX
        @previousMouseY = event.targetTouches[0].pageY

  # Binds the touchup handler so we know when
  # the dragging ends.
  bindTouchUp: () ->
    @content.addEventListener "touchup", (event) =>
      @dragging = false
      event.preventDefault()

  # Binds the mousemove handler so we can detect
  # dragging motions.
  bindMouseMove: () ->
    @content.addEventListener "mousemove", (event) =>
      if @dragging and @listening
        event.preventDefault()
        @drag event.clientX, event.clientY
        @previousMouseX = event.clientX
        @previousMouseY = event.clientY

  # Binds the touchmove handler so we can detect
  # dragging motions.
  bindTouchMove: () ->
    @content.addEventListener "touchmove", (event) =>
      if @dragging and @listening
        event.preventDefault()
        @drag event.targetTouches[0].pageX, event.targetTouches[0].pageY
        @previousMouseX = event.targetTouches[0].pageX
        @previousMouseY = event.targetTouches[0].pageY

  # Uses the new position of the mouse to move the content.
  drag: (currentMouseX, currentMouseY) =>
    movementX = (currentMouseX - @previousMouseX)
    movementY = (currentMouseY - @previousMouseY)
    fg.mindmap.animation.moveSingleFrame(movementX, movementY)
