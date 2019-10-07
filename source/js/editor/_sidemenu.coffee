# Represents the editor sidemenu used to edit and
# manage the contents of the map.
class SideMenu

  # Creates the DOM-object for the editor-sidemenu and inserts
  # it into the page.
  constructor: () ->
    @content = document.getElementById("content")
    @closed = true

    # Build the sidemenu basics.
    @buildSideMenu()

    @sliding = false
    @previousMouseX = 0

  # Binds all eventlisteners.
  startListening: () ->
    @bindSlideButton()
    @bindSliderMouseDown()
    @bindSliderMouseUp()
    @bindSliderMouseMove()
    @bindSaveButton()

  # Binds the eventlisteners to the slide in/out button.
  bindSlideButton: () ->
    @slideButton.addEventListener "click", () =>
      if @sidemenu.classList.contains("sidemenu-open")
        @slideButton.classList.add "closed"
        @slideOut()
      else
        @slideButton.classList.remove "closed"
        @slideIn()

  # Binds the mousedown handler so we know when the users starts
  # expanding or shrinking the sidemenu.
  bindSliderMouseDown: () ->
    @sidemenuSlider.addEventListener "mousedown", (event) =>
      event.preventDefault()
      @sliding = true
      @previousMouseX = event.clientX

  # Binds the mouseup handler so we know when the users stops
  # expanding or shrinking the sidemenu.
  bindSliderMouseUp: () ->
    document.addEventListener "mouseup", (event) =>
      event.preventDefault()
      @sliding = false

  # Binds the mousemove handler so we know how to expand
  # or shrink the sidemenu based on the user's mouse movements.
  bindSliderMouseMove: () ->
    document.addEventListener "mousemove", (event) =>
      if @sliding
        event.preventDefault()
        movement = event.clientX - @previousMouseX
        newWidth = Math.min(Math.max(@sidemenu.clientWidth - movement, window.screen.width * 0.15), window.screen.width * 0.6)

        @sidemenu.style.width = newWidth + "px"
        @sidemenu.style.left = "calc(100% - " + newWidth + "px)"

        @content.style.width = "calc(100% - " + newWidth + "px)"

        @previousMouseX = event.clientX

  # Starts an animation to shrink the main content view
  # while sliding in the sidemenu.
  slideIn: () ->
    @closed = false
    @content.removeAttribute "style"
    @sidemenu.removeAttribute "style"
    @content.classList.remove "sidemenu-closed"
    @content.classList.add "sidemenu-open"
    @sidemenu.classList.add "sidemenu-open"
    @sidemenu.classList.remove "sidemenu-closed"

  # Starts an animation to expand the main content view
  # while sliding out the sidemenu.
  slideOut: () ->
    @closed = true
    @content.removeAttribute "style"
    @sidemenu.removeAttribute "style"
    @content.classList.remove "sidemenu-open"
    @content.classList.add "sidemenu-closed"
    @sidemenu.classList.remove "sidemenu-open"
    @sidemenu.classList.add "sidemenu-closed"

  # Builds and inserts the HTML for the editor sidemenu.
  buildSideMenu: () ->
    # The sidemenu div itself.
    @sidemenu = document.createElement "div"
    @sidemenu.id = "editor-sidemenu"

    # The header.
    header = document.createElement "div"
    header.id = "editor-sidemenu-header"
    @sidemenu.appendChild header

    title = document.createElement "h2"
    title.innerHTML = "Flow & Grow Editor"
    header.appendChild title

    @lastSaved = document.createElement "h4"
    @lastSaved.id = "editor-sidemenu-last-saved"
    @lastSaved.innerHTML = "Laatst opgeslagen: nooit"
    header.appendChild @lastSaved

    # Open/close button
    @slideButton = document.createElement "button"
    @slideButton.id = "editor-sidemenu-slidebutton"
    @slideButton.innerHTML = "<i class='fas fa-angle-double-right'></i>"
    @sidemenu.appendChild @slideButton

    # The slider to make the sidemenu smaller or bigger.
    @sidemenuSlider = document.createElement "div"
    @sidemenuSlider.id = "editor-sidemenu-slider"
    @sidemenu.appendChild @sidemenuSlider

    # The content of the sidemenu.
    @sidemenuContent = document.createElement "div"
    @sidemenuContent.id = "editor-sidemenu-content"
    @sidemenu.appendChild @sidemenuContent

    # Placeholder text.
    placeholder = document.createElement "div"
    placeholder.id = "editor-sidemenu-placeholder"
    placeholder.innerHTML = "Gebruik <b>alt + muisklik</b> om een element te bewerken."
    @sidemenuContent.appendChild placeholder

    # The footer.
    footer = document.createElement "div"
    footer.id = "editor-sidemenu-footer"
    @sidemenu.appendChild footer

    # Save button.
    @saveButton = document.createElement "button"
    @saveButton.id = "editor-sidemenu-savebutton"
    @saveButton.innerHTML = "Opslaan&nbsp;&nbsp;<i class='fas fa-save'></i>"
    footer.appendChild @saveButton

    # 'Notificaton' banner.
    @banner = document.createElement "div"
    @banner.id = "editor-sidemenu-banner"
    footer.appendChild @banner

    document.getElementById("container").appendChild @sidemenu

  # Resets the state of the sidemenu to the placeholder text.
  reset: () ->
    placeholder = document.createElement "div"
    placeholder.id = "editor-sidemenu-placeholder"
    placeholder.innerHTML = "Gebruik <b>alt + muisklik</b> om een element te bewerken."
    @sidemenuContent.innerHTML = ""
    @sidemenuContent.appendChild placeholder

  # Displays a success-message in the footer banner.
  successMessage: (message) ->
    @banner.innerHTML = message
    @banner.className = "success"
    setTimeout ( =>
      @banner.className = ""
      @banner.innerHTML = ""
    ), 5000

  # Displays an error-message in the footer banner.
  errorMessage: (message) ->
    @banner.innerHTML = message
    @banner.className = "error"
    setTimeout ( =>
      @banner.className = ""
      @banner.innerHTML = ""
    ), 5000

  # Binds the click-listener to the save-button.
  bindSaveButton: () ->
    @saveButton.addEventListener "click", () =>
      @saveButton.disabled = true
      @saveButton.innerHTML = "Aan het opslaan...&nbsp;&nbsp;<i class='fas fa-pause-circle'></i>"
      httpRequest = new XMLHttpRequest()
      httpRequest.onreadystatechange = () =>
        if httpRequest.readyState == XMLHttpRequest.DONE
          if httpRequest.status == 200
            @lastSaved.innerHTML = "Laatst opgeslagen: #{("0" + new Date().getHours()).slice(-2)}:#{("0" + new Date().getMinutes()).slice(-2)}"
            @successMessage "Mindmap opgeslagen!"
            @saveButton.innerHTML = "Opslaan&nbsp;&nbsp;<i class='fas fa-save'></i>"
            @saveButton.disabled = false
          else
            @errorMessage("Kon de mindmap niet opslaan!")
            console.error "Couldn't save!", httpRequest
            @saveButton.innerHTML = "Opslaan&nbsp;&nbsp;<i class='fas fa-save'></i>"
            @saveButton.disabled = false
      httpRequest.open("post", "save.php")
      httpRequest.setRequestHeader("Content-Type", "application/json", true)

      cleanData = (json) =>

        updateWeight = (node) =>
          node.weight = Array.from(node.element.parentNode.childNodes).indexOf(node.element)
          delete node["element"]

        cleanChildren = (node) =>
          if node["parentObject"]
            delete node["parentObject"]
          if node.element
            updateWeight(node)
          if node.children
            for child in node.children
              cleanChildren(child)

        for study in Object.keys(json.studies)
          for year in Object.keys(json.studies[study].years)
            for node in json.studies[study].years[year].nodes

              if node.element
                updateWeight(node)

              for child in node.children
                cleanChildren(child)
        return json

      httpRequest.send(JSON.stringify(cleanData(window.fg.mindmap.data)))
