# Provides a simple interface to interact with the
# mindmap and its contents.
class Mindmap

  # Initializes the mindmap by loading all needed data.
  # Triggers the callback when the data is loaded.
  constructor: (callback = false) ->
    # Basic elements.
    @container = document.getElementById "mindmap"
    @rootNode = document.getElementById "rootnode"
    @content = document.getElementById "content"
    @privacyPopup = document.getElementById "privacy-popup"

    # Animating and moving of the mindmap.
    @animation = new Animation(@container)

    # The zoom-level of the mindmap.
    @zoomFactor = 1.0

    @loadData(callback)

  # Uses an AJAX call to load the mindmap data.
  loadData: (callback) ->
    httpRequest = new XMLHttpRequest()
    httpRequest.onreadystatechange = () =>
      if httpRequest.readyState == XMLHttpRequest.DONE
        if httpRequest.status == 200

          # Data is successfully loaded, so let's display it to the user.
          @data = JSON.parse(httpRequest.responseText)
          @createStudySelectBalloon()

          if callback
            callback()
        else
          @data = {}
          console.error "Couldn't load the map data!"
    httpRequest.open("GET", "data/content.json")
    httpRequest.send()

  # Updates the contents of the textbubble using a fade-in and
  # fade-out animation. Removes the old bubble from the DOM.
  updateTextBubbleContent: (newContent) ->
    for oldBubble in document.getElementsByClassName("textbubble")
      return if oldBubble.innerText.replace(/^\s+|\s+|\n+$/gm, '') == newContent.innerText.replace(/^\s+|\s+|\n+$/gm, '')
      oldBubble.addEventListener "animationend", () ->
        if oldBubble.parentElement
          oldBubble.parentElement.removeChild(oldBubble)
      oldBubble.addEventListener "webkitAnimationEnd", () ->
        if oldBubble.parentElement
          oldBubble.parentElement.removeChild(oldBubble)
      oldBubble.classList.add "bubbleFadeOut"
    fadeOutAnimation = new Animation(oldBubble)

    newBubble = document.createElement "div"
    newBubble.className = "textbubble bubbleFadeIn"
    newBubble.appendChild newContent
    fadeInAnimation = new Animation(newBubble)

    @rootNode.appendChild newBubble

  # Creates the balloon that allows the user to pick his or her
  # study and year.
  createStudySelectBalloon: () ->

    # Create the HTML for the study-select balloon.
    studySelectBalloon = document.createElement "span"
    studySelectBalloon.className = "textBubbleContent studySelect no-drag"

    # The text-label.
    selectStudyLabel = document.createElement "label"
    selectStudyLabel.innerHTML = "Kies je studie en studiejaar:"
    studySelectBalloon.appendChild selectStudyLabel

    # The study select-input.
    studySelectContainer = document.createElement "span"
    studySelectContainer.className = "dropdown"
    @studySelect = document.createElement "select"
    @studySelect.id = "studySelect"
    disabledPlaceholder = new Option("Selecteer je studie", null, true, true)
    disabledPlaceholder.disabled = true
    disabledPlaceholder.classList.add("placeholder")
    @studySelect.appendChild disabledPlaceholder
    studySelectContainer.appendChild @studySelect
    studySelectBalloon.appendChild studySelectContainer

    # The year select-input.
    yearSelectContainer = document.createElement "span"
    yearSelectContainer.className = "dropdown"
    @yearSelect = document.createElement "select"
    @yearSelect.id = "yearSelect"
    @yearSelect.disabled = true
    disabledPlaceholder = new Option("Selecteer je studiejaar", null, true, true)
    disabledPlaceholder.classList.add("placeholder")
    disabledPlaceholder.disabled = true
    @yearSelect.appendChild disabledPlaceholder
    yearSelectContainer.appendChild @yearSelect
    studySelectBalloon.appendChild yearSelectContainer

    # The submit-button.
    @studySelectButton = document.createElement "button"
    @studySelectButton.id = "studySelectButton"
    @studySelectButton.innerHTML = "OK"
    @studySelectButton.disabled = true
    studySelectBalloon.appendChild @studySelectButton

    # Load and sort all studynames.
    studies = Object.keys(@data.studies)

    @sortedStudies = studies.sort (a, b) =>
      weightA = parseInt(@data.studies[a].data.weight)
      weightB = parseInt(@data.studies[b].data.weight)
      return  1 if (weightA > weightB)
      return -1 if (weightA < weightB)
      return  0

    # Insert the studies in the select-input.
    for study in @sortedStudies
      @studySelect.appendChild new Option(study, studies.indexOf(study))

    # Add the eventlisteners.
    @bindStudySelect()

    # Show the balloon.
    @updateTextBubbleContent studySelectBalloon

  # Binds the eventlisteners that allow the user to pick and choose
  # their study and year.
  bindStudySelect: () ->
    studyWeight = null

    # Load all year options when a study is picked.
    @studySelect.addEventListener "change", () =>

      # Assure the ok-button is still disabled as it should be,
      # since picking a study still requires you to select a year.
      @studySelectButton.disabled = true
      studyWeight = parseInt(@studySelect.value) + 1
      years = @data.studies[`Object.keys(window.fg.mindmap.data.studies).find(key => window.fg.mindmap.data.studies[key].data.weight == studyWeight)`].years
      yearOptions = Object.keys(years)
      sortedYearOptions = yearOptions.concat().sort (a,b) ->
        weightA = parseInt(years[a].data.weight)
        weightB = parseInt(years[b].data.weight)
        return  1 if (weightA > weightB)
        return -1 if (weightA < weightB)
        return  0

      # If there are any options, enable the year selection and submit button.
      @yearSelect.disabled = (yearOptions.length == 0)

      # Remove all previous options.
      for oldOption in @yearSelect.querySelectorAll("option:not([class='placeholder'])")
        @yearSelect.removeChild oldOption

      # Insert the new options.
      for year in sortedYearOptions
        @yearSelect.add new Option(year, yearOptions.indexOf(year))

      # Set the default option back to the placeholder.
      @yearSelect.value = null

    # Enable the ok-button when a year has been selected.
    @yearSelect.addEventListener "change", () =>
      @studySelectButton.disabled = false

    # Loads the selected study and year when the ok-button is pressed.
    @studySelectButton.addEventListener "click", () =>
      @selectedStudy = `Object.keys(window.fg.mindmap.data.studies).find(key => window.fg.mindmap.data.studies[key].data.weight == studyWeight)`
      @selectedYear = Object.keys(@data.studies[@selectedStudy]["years"])[@yearSelect.value]
      @mindmapData = @data.studies[@selectedStudy]["years"][@selectedYear]
      @renderMindMap()

  # Renders the given mindmap data to the screen,
  # adding all click handlers on the way.
  renderMindMap: () ->

    # Update the textbubble.
    welcomeBubble = document.createElement "span"
    welcomeBubble.className = "textBubbleContent standard"
    welcomeBubble.innerHTML = @data.studies[@selectedStudy].data.welcomeMessage
    @updateTextBubbleContent(welcomeBubble)

    # Create and render node-objects for every node.
    sortedNodes = @mindmapData.nodes.sort (a,b) ->
      weightA = parseInt(a.weight)
      weightB = parseInt(b.weight)
      return  1 if (weightA > weightB)
      return -1 if (weightA < weightB)
      return  0

    for nodeData in sortedNodes
      node = new supportedNodeTypes[nodeData.type](nodeData, true)
      node.build().addListeners().render()

    # Display the reset and show-all buttons.
    document.getElementById("reset-button").style.display = "inline-block"
    document.getElementById("reset-button").classList.add "fade-in"

    # Show the hint after 5 seconds.
    setTimeout ( =>
      hint = document.querySelector("#hint")
      hint.classList.add "fade-in"
      setTimeout ( =>
        hint.classList.remove "fade-in"
        hint.classList.add "fade-out"
        hint.addEventListener "animationend", () =>
          hint.parentElement.removeChild hint
      ), 7000
    ), 1000

  # Animates the mindmap moving to its center.
  moveToCenter: () ->

    rootTargetX = Math.ceil(document.getElementById("content").offsetWidth / 2 - @rootNode.offsetWidth / 2)
    rootTargetY = Math.ceil(document.getElementById("content").offsetHeight / 2 - @rootNode.offsetHeight  / 2)

    rootCurrentX = Math.ceil(@rootNode.getBoundingClientRect().left)
    rootCurrentY = Math.ceil(@rootNode.getBoundingClientRect().top)

    moveX = (rootTargetX - rootCurrentX)
    moveY = (rootTargetY - rootCurrentY)

    @animation.moveRelative(moveX, moveY, 500)

  # Displays the privacy popup.
  showPrivacyPopup: () ->
    removePopup = () =>
      animationEnd = () =>
        @privacyPopup.style.display = "none"
        @privacyPopup.removeEventListener "animationend", animationEnd
      @privacyPopup.addEventListener "animationend", animationEnd
      @privacyPopup.classList.remove "fade-in"
      @privacyPopup.classList.add "fade-out"
      @privacyPopup.querySelector("#accept-button").removeEventListener("click", removePopup)
      @removeOverlay()

    @showOverlay(removePopup)
    @privacyPopup.style.display = "block"
    @privacyPopup.classList.remove "fade-out"
    @privacyPopup.classList.add "fade-in"

    @privacyPopup.querySelector("#accept-button").addEventListener "click", removePopup

  # Displays a semi-transparent, dark overlay over the screen
  # to emphasize a popup.
  showOverlay: (callback = false) ->
    overlay = document.createElement "div"
    overlay.id = "overlay"
    overlay.classList.add "fade-in"
    overlay.addEventListener "click", () =>
      if callback
        callback()
      @removeOverlay()
    @content.appendChild overlay

  # Removes the overlay from the screen.
  removeOverlay: () ->
    overlay = @content.querySelector "#overlay"
    overlay.classList.remove "fade-in"
    overlay.classList.add "fade-out"
    overlay.addEventListener "animationend", () =>
      if @content.contains overlay
        @content.removeChild overlay

  # Resets the state of the mindmap.
  # Keeps the selected study and year.
  reset: () ->

    # Unchecks all checkboxes, resets the progressbars and collapses
    # the checklist nodes and their subtrees.
    for node in @container.querySelectorAll ".root-child"
      for checkbox in node.querySelectorAll "input[type='checkbox']"
        checkbox.checked = false
      for progressBar in node.querySelectorAll ".bar"
        progressBar.style.width = "0px"
      if node.querySelector(".node").classList.contains("active")
        node.querySelector(".node-content-header").click()
      expandButton = node.querySelector(".node-expand")
      if expandButton and expandButton.classList.contains "active"
        expandButton.click()

    # Updates the textbubble.
    if @data.studies[@selectedStudy].data.resetMessage and @data.studies[@selectedStudy].data.resetMessage.length
      resetMessage = document.createElement "span"
      resetMessage.classList.add "textBubbleContent", "standard"
      resetMessage.innerHTML = @data.studies[@selectedStudy].data.resetMessage
      @updateTextBubbleContent resetMessage

    # Reset the position.
    @moveToCenter()

  # Zooms out the mindmap by 0.25 at a time.
  # Has a minimum zoomfactor of 0.25.
  zoomOut: () ->
    @zoomFactor = Math.max(@zoomFactor - 0.25, 0.25)
    @animation.scale(@zoomFactor)

  # Zooms in the mindmap by 0.25 at a time.
  # Has a maximum zoomfactor of 2.0.
  zoomIn: () ->
    @zoomFactor = Math.min(@zoomFactor + 0.25, 2.0)
    @animation.scale(@zoomFactor)
