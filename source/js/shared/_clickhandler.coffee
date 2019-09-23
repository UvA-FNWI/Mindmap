# Provides a simple interface to add click listeners
# to all buttons.
class ClickHandler

  # Initializes the variables pointing to all
  # objects that can be clicked.
  constructor: () ->
    @resetPositionButton = document.getElementById "reset-position-button"
    @privacyButton = document.getElementById "privacy-button"
    @resetButton = document.getElementById "reset-button"
    @zoomInButton = document.getElementById "zoom-in-button"
    @zoomOutButton = document.getElementById "zoom-out-button"


  # Binds all click listeners.
  startListening: () ->
    @bindPrivacyButton()
    @bindResetButton()
    @bindResetPositionButton()
    @bindZoomButtons()

  # Binds the buttons to zoom in and out on the mindmap.
  bindZoomButtons: () ->
    @zoomInButton.addEventListener "click", () ->
      fg.mindmap.zoomIn()
    @zoomOutButton.addEventListener "click", () ->
      fg.mindmap.zoomOut()

  # Displays or removes the privacy popup.
  bindPrivacyButton: () ->
    @privacyButton.addEventListener "click", () =>
      fg.mindmap.showPrivacyPopup()

  # Resets the state of the mindmap.
  bindResetButton: () ->
    @resetButton.addEventListener "click", () ->
      fg.mindmap.reset()

  # Resets the mindmap position on click.
  bindResetPositionButton: () ->
    @resetPositionButton.addEventListener "click", () ->
      fg.mindmap.moveToCenter()

