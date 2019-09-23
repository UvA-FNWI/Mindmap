# Provides a simple link between nodes and
# the editor sidemenu.
class Editor

  # Hooks onto the nodes' click-event and links
  # all alt-clicks from the standard eventlisteners to the
  # editor-listeners.
  editorLink: (node, event) =>
    if event.altKey

      # Highlight the clicked node.
      previousNode = document.querySelector(".editor-selected")
      previousNode.classList.remove "editor-selected" if previousNode
      node.html.querySelector(".node").classList.add "editor-selected"

      @node = node
      @editorContent = document.getElementById("editor-sidemenu-content")

      # Open the node in the editor and, if it was closed, open the editor.
      @openInEditor()
      window.fg.sidemenu.slideIn() if window.fg.sidemenu.closed

      event.stopPropagation()
      return true
    else
      return false

  # Opens the selected node in the editor so its
  # properties can be edited.
  openInEditor: () ->

    # First remove all old content from the editor.
    @editorContent.innerHTML = ""

    # Add all editable items to the sidemenu.
    for property, value of @node.nodeData

      # Unpack nested properties.
      if typeof value == "object"
        for prop, val of value
          if "#{property}_#{prop}" in EDITABLE_PROPERTIES
            @createItem("#{property}_#{prop}", val).addToEditor()
      else
        if property in EDITABLE_PROPERTIES
          @createItem(property, value).addToEditor()

    # Default add/remove buttons for every node.
    @addRemoveButtonCreate().addToEditor()

    # Start listening for changes in the editor to automatically
    # update the node.
    @listenForChanges()

    this

  # Adds the button to the study-select balloon to launch that
  # enables the user to edit the studies.
  addEditStudiesButton: () ->
    bubble = document.querySelector(".textBubbleContent.studySelect")

    button = document.createElement "button"
    button.id = "edit-studies-button"
    button.innerHTML = "Pas studies aan <i class='far fa-edit'></i>"
    button.addEventListener "click", @studiesEditor
    bubble.appendChild button

    this

  # Creates a popup that enables the user to edit
  # studies, years and their order.
  studiesEditorOpen = false
  studiesEditor: () ->
    if studiesEditorOpen
      return

    studiesEditorOpen = true

    # Create the popup-container to hold everything.
    studiesEditorContainer = document.createElement "div"
    studiesEditorContainer.id = "studies-editor-container"
    studiesEditorContainer.className = "no-drag"


    openStudyListener = (e) =>
      if e.target.closest(".study-row").classList.contains "active"
        return

      for item in document.querySelectorAll(".study-row")
        item.classList.remove "active"

      studyItem = e.target.closest(".study-row")
      studyItem.classList.add "active"
      study = studyItem.getAttribute "data-study"
      studyData = window.fg.mindmap.data.studies[study]
      detailsContainer = document.querySelector("#details-column")

      detailsContainer.innerHTML = ""

      # Study itself.
      title = document.createElement "h2"
      title.id = "study-title"
      title.innerText = study
      detailsContainer.appendChild title

      info = document.createElement "h6"
      info.className = "study-info"
      info.innerText = "#{Object.keys(studyData.years).length} studiejaren"
      detailsContainer.appendChild info

      divider = document.createElement("hr")
      detailsContainer.appendChild divider

      actionsTitle = document.createElement "h3"
      actionsTitle.innerText = "Acties"
      detailsContainer.appendChild actionsTitle

      buttonContainer = document.createElement "div"
      buttonContainer.id = "buttonContainer"

      copyButton = document.createElement "button"
      copyButton.id = "copy-study-button"
      copyButton.innerHTML = "Studie dupliceren <i class='far fa-copy'></i>"
      copyButton.addEventListener "click", () =>
        copiedName = window.prompt "Wat is de naam van de nieuwe studie?"
        window.fg.mindmap.data.studies[copiedName] = JSON.parse(JSON.stringify(window.fg.mindmap.data.studies[study]))
        window.fg.mindmap.data.studies[copiedName].data.weight = Object.keys(window.fg.mindmap.data.studies).length

        option = document.createElement "option"
        option.value = window.fg.mindmap.data.studies[copiedName].data.weight - 1
        option.innerText = copiedName
        document.querySelector("#studySelect").appendChild option
        window.fg.mindmap.sortedStudies.push copiedName

        item = document.createElement "div"
        item.classList.add "study-row"
        item.setAttribute "data-study", copiedName

        name = document.createElement "span"
        name.className = "study-name"
        name.innerHTML = copiedName
        item.appendChild name

        years = document.createElement "span"
        years.className = "study-year-count"
        years.innerHTML = "#{Object.keys(window.fg.mindmap.data.studies[copiedName].years).length} studiejaren"
        item.appendChild years

        item.addEventListener "click", (e) =>
          openStudyListener(e)

        studiesColumn.insertBefore item, document.querySelector "#add-study-button"

      buttonContainer.appendChild copyButton

      deleteButton = document.createElement "button"
      deleteButton.id = "delete-study-button"
      deleteButton.innerHTML = "Studie verwijderen <i class='far fa-trash-alt'></i>"
      deleteButton.addEventListener "click", () =>
        if window.confirm "Weet je zeker dat je de studie '#{study}' wil verwijderen?"
          delete window.fg.mindmap.data.studies[study]
          studyItem.parentElement.removeChild studyItem
          window.fg.mindmap.sortedStudies.splice(window.fg.mindmap.sortedStudies.indexOf(study), 1)
          for option in document.querySelectorAll "#studySelect option"
            if option.innerText == study
              option.parentElement.removeChild option
              return
          document.querySelector("#details-column").innerHTML = "<h3>'#{study}' is verwijderd</h3>"
      buttonContainer.appendChild deleteButton

      renameButton = document.createElement "button"
      renameButton.id = "rename-study-button"
      renameButton.innerHTML = "Studie hernoemen <i class='far fa-edit'></i>"
      renameButton.addEventListener "click", () =>
       newName = window.prompt "Wat is de nieuwe naam van de studie?"
       if newName
        study[window.fg.mindmap.sortedStudies.indexOf(study)] = newName
        window.fg.mindmap.data.studies[newName] = JSON.parse(JSON.stringify(window.fg.mindmap.data.studies[study]))
        delete window.fg.mindmap.data.studies[study]
        document.querySelector("#study-title").innerText = newName
        row = document.querySelector("#studies-column .study-row[data-study='#{study}']")
        row.setAttribute "data-study", newName
        row.querySelector(".study-name").innerText = newName
        document.querySelector("#studySelect option[value='#{window.fg.mindmap.sortedStudies.indexOf("BSc Blyat")}']").innerText = newName
      buttonContainer.appendChild renameButton

      moveUpButton = document.createElement "button"
      moveUpButton.id = "move-up-button"
      moveUpButton.innerHTML = "Omhoog <i class='fas fa-sort-up'></i>"
      if studyData.data.weight == 1
        moveUpButton.disabled = true
      moveUpButton.addEventListener "click", () =>
        moveDownButton.disabled = false
        higherStudy = `Object.keys(window.fg.mindmap.data.studies).find(key => window.fg.mindmap.data.studies[key].data.weight == studyData.data.weight - 1)`
        higherWeight = window.fg.mindmap.data.studies[higherStudy].data.weight
        window.fg.mindmap.data.studies[higherStudy].data.weight = studyData.data.weight
        studyData.data.weight = higherWeight
        studyItem.parentNode.insertBefore(studyItem, studyItem.previousElementSibling)
        if studyData.data.weight == 1
          moveUpButton.disabled = true

        window.fg.mindmap.sortedStudies = []
        document.querySelector("#studySelect").innerHTML = "<option value='null' selected='' disabled='' class='placeholder'>Selecteer je studie</option>"
        for studyRow, index in document.querySelectorAll "#studies-column .study-row"
          name = studyRow.getAttribute "data-study"
          window.fg.mindmap.sortedStudies.push name
          o = document.createElement "option"
          o.value = index
          o.innerText = name
          document.querySelector("#studySelect").appendChild o
      buttonContainer.appendChild moveUpButton

      moveDownButton = document.createElement "button"
      moveDownButton.id = "move-down-button"
      moveDownButton.innerHTML = "Omlaag <i class='fas fa-sort-down'></i>"
      if studyData.data.weight == Object.keys(window.fg.mindmap.data.studies).length
        moveDownButton.disabled = true
      moveDownButton.addEventListener "click", () =>
        moveUpButton.disabled = false
        lowerStudy = `Object.keys(window.fg.mindmap.data.studies).find(key => window.fg.mindmap.data.studies[key].data.weight == studyData.data.weight + 1)`
        lowerWeight = window.fg.mindmap.data.studies[lowerStudy].data.weight
        window.fg.mindmap.data.studies[lowerStudy].data.weight = studyData.data.weight
        studyData.data.weight = lowerWeight
        studyItem.parentNode.insertBefore(studyItem.nextElementSibling, studyItem)
        if studyData.data.weight == Object.keys(window.fg.mindmap.data.studies).length
          moveDownButton.disabled = true

        window.fg.mindmap.sortedStudies = []
        document.querySelector("#studySelect").innerHTML = "<option value='null' selected='' disabled='' class='placeholder'>Selecteer je studie</option>"
        for studyRow, index in document.querySelectorAll "#studies-column .study-row"
          name = studyRow.getAttribute "data-study"
          window.fg.mindmap.sortedStudies.push name
          o = document.createElement "option"
          o.value = index
          o.innerText = name
          document.querySelector("#studySelect").appendChild o

      buttonContainer.appendChild moveDownButton

      detailsContainer.appendChild buttonContainer

      # Messages.
      messageDivider = document.createElement "hr"
      detailsContainer.appendChild messageDivider

      messagesTitle = document.createElement "h3"
      messagesTitle.innerText = "Berichten"
      detailsContainer.appendChild messagesTitle

      welcomeTitle = document.createElement "h6"
      welcomeTitle.className = "message-title"
      welcomeTitle.innerText = "Welkomst-tekst"
      detailsContainer.appendChild welcomeTitle

      welcomeEdit = document.createElement "input"
      welcomeEdit.className = "message-edit"
      welcomeEdit.value = studyData.data.welcomeMessage || "Lorem ipsum dolor"
      welcomeEdit.addEventListener "click", () =>
        window.fg.editor.createWYSIWYGEditor welcomeEdit.value, (value) ->
          welcomeEdit.value = value
          window.fg.mindmap.data.studies[study].data.welcomeMessage = value
      detailsContainer.appendChild welcomeEdit

      resetTitle = document.createElement "h6"
      resetTitle.className = "message-title"
      resetTitle.innerText = "Reset-tekst"
      detailsContainer.appendChild resetTitle

      resetEdit = document.createElement "input"
      resetEdit.className = "message-edit"
      resetEdit.value = studyData.data.resetMessage || "Lorem ipsum dolor"
      resetEdit.addEventListener "click", () =>
        window.fg.editor.createWYSIWYGEditor resetEdit.value, (value) ->
          resetEdit.value = value
          window.fg.mindmap.data.studies[study].data.resetMessage = value
      detailsContainer.appendChild resetEdit

      # Study years.
      yearsDivider = document.createElement "hr"
      detailsContainer.appendChild yearsDivider

      yearsTitle = document.createElement "h3"
      yearsTitle.innerText = "Studiejaren"
      detailsContainer.appendChild yearsTitle

      yearsContainer = document.createElement "ul"
      yearsContainer.id = "years-container"

      studyYears = Object.keys(studyData.years)
      sortedStudyYears = studyYears.sort (a,b) ->
        weightA = parseInt(studyData.years[a].data.weight)
        weightB = parseInt(studyData.years[b].data.weight)
        return  1 if (weightA > weightB)
        return -1 if (weightA < weightB)
        return  0

      createYearItem = (year) =>
        `let yearName = year`
        `let item = document.createElement("li")`
        name = document.createElement "label"
        name.innerText = yearName
        item.appendChild name

        deleteButton = document.createElement "button"
        deleteButton.className = "delete"
        deleteButton.innerHTML = "<i class='far fa-trash-alt'></i>"
        deleteButton.addEventListener "click", () =>
          if window.confirm "Weet je zeker dat je het studiejaar '#{yearName}' wilt verwijderen?"
            yearsContainer.removeChild item
            delete studyData.years[yearName]
        item.appendChild deleteButton

        dupButton = document.createElement "button"
        dupButton.className = "duplicate"
        dupButton.innerHTML = "<i class='far fa-copy'></i>"
        dupButton.addEventListener "click", () =>
          dupName = window.prompt "Wat is de naam van de nieuwe studie?"
          if dupName
            window.fg.mindmap.data.studies[study].years[dupName] = JSON.parse(JSON.stringify(studyData.years[yearName]))
            window.fg.mindmap.data.studies[study].years[dupName].data.weight = Object.keys(studyData.years).length
            document.querySelector("#years-container .order.down:disabled").disabled = false
            studyCount = parseInt(document.querySelector("#studies-column [data-study='#{study}'] .study-year-count").innerText) + 1
            document.querySelector("#studies-column [data-study='#{study}'] .study-year-count").innerText = "#{studyCount} studiejaren"
            document.querySelector("#details-column h6").innerText = "#{studyCount} studiejaren"
            createYearItem dupName
        item.appendChild dupButton

        `let downButton = document.createElement("button")`
        downButton.className = "order down"
        downButton.innerHTML = "<i class='fas fa-sort-down'></i>"
        if parseInt(studyData.years[yearName].data.weight) == Object.keys(studyData.years).length
          downButton.disabled = true

        item.appendChild downButton

        `let upButton = document.createElement("button")`
        upButton.className = "order up"
        upButton.innerHTML = "<i class='fas fa-sort-up'></i>"
        if parseInt(studyData.years[yearName].data.weight) == 1
          upButton.disabled = true
        item.appendChild upButton

        downButton.addEventListener "click", () =>
          lowerYear = `Object.keys(studyData.years).find(key => studyData.years[key].data.weight == parseInt(studyData.years[yearName].data.weight) + 1)`
          studyData.years[lowerYear].data.weight -= 1

          item.nextElementSibling.querySelector(".order.down").disabled = downButton.disabled
          item.nextElementSibling.querySelector(".order.up").disabled = upButton.disabled
          upButton.disabled = false
          yearsContainer.insertBefore(item.nextElementSibling, item)
          studyData.years[yearName].data.weight = parseInt(studyData.years[yearName].data.weight) + 1
          if parseInt(studyData.years[yearName].data.weight) == Object.keys(studyData.years).length
            downButton.disabled = true

        upButton.addEventListener "click", () =>
          higherYear = `Object.keys(studyData.years).find(key => studyData.years[key].data.weight == parseInt(studyData.years[yearName].data.weight) - 1)`
          studyData.years[higherYear].data.weight += 1

          item.previousElementSibling.querySelector(".order.down").disabled = downButton.disabled
          item.previousElementSibling.querySelector(".order.up").disabled = upButton.disabled
          downButton.disabled = false
          yearsContainer.insertBefore(item, item.previousElementSibling)
          studyData.years[yearName].data.weight = parseInt(studyData.years[yearName].data.weight) - 1
          if parseInt(studyData.years[yearName].data.weight) == 1
            upButton.disabled = true

        changeNameButton = document.createElement "button"
        changeNameButton.className = "edit"
        changeNameButton.innerHTML = "<i class='far fa-edit'></i>"
        changeNameButton.addEventListener "click", () =>
          newName = window.prompt "Wat is de nieuwe naam van '#{yearName}'?"
          if newName
            studyData.years[newName] = JSON.parse(JSON.stringify(studyData.years[yearName]))
            name.innerText = newName
            delete studyData.years[yearName]
        item.appendChild changeNameButton

        yearsContainer.appendChild item

      for year in sortedStudyYears
        createYearItem(year)

      detailsContainer.appendChild yearsContainer

      addYearButton = document.createElement "button"
      addYearButton.id = "add-year-button"
      addYearButton.innerHTML = "Jaar toevoegen <i class='fas fa-plus-square'></i>"
      addYearButton.addEventListener "click", () =>
        yearName = window.prompt "Wat is de naam van het nieuwe studiejaar?"
        if yearName
          studyData.years[yearName] = {
            data: {
              weight: Object.keys(studyData.years).length + 1
            },
            nodes: [{
              children: [],
              name: "Nieuwe node...."
              color: "#6b2565",
              type: "text",
              messages: {}
              data: {
                text: "Lorem ipsum dolor sit amet"
              },
              side: "left",
              weight: 1
            }]
          }
          createYearItem yearName
          studyCount = parseInt(document.querySelector("#studies-column [data-study='#{study}'] .study-year-count").innerText) + 1
          document.querySelector("#studies-column [data-study='#{study}'] .study-year-count").innerText = "#{studyCount} studiejaren"
          document.querySelector("#details-column h6").innerText = "#{studyCount} studiejaren"

      detailsContainer.appendChild addYearButton


    # Create the left column containing the studies.
    studiesColumn = document.createElement "div"
    studiesColumn.id = "studies-column"
    for study in window.fg.mindmap.sortedStudies
      item = document.createElement "div"
      item.classList.add "study-row"
      item.setAttribute "data-study", study

      name = document.createElement "span"
      name.className = "study-name"
      name.innerHTML = study
      item.appendChild name

      years = document.createElement "span"
      years.className = "study-year-count"
      years.innerHTML = "#{Object.keys(window.fg.mindmap.data.studies[study].years).length} studiejaren"
      item.appendChild years

      item.addEventListener "click", (e) =>
        openStudyListener(e)

      studiesColumn.appendChild item
    studiesEditorContainer.appendChild studiesColumn

    # Create the button to add a study.
    addStudyButton = document.createElement "button"
    addStudyButton.id = "add-study-button"
    addStudyButton.innerHTML = "Studie toevoegen <i class='fas fa-plus-square'></i>"
    addStudyButton.addEventListener "click", () =>
      newStudyName = window.prompt "Wat is de naam van de toe te voegen studie?"
      if newStudyName
        # Add the study to the datastructure.
        newStudyWeight = Object.keys(window.fg.mindmap.data.studies).length + 1
        window.fg.mindmap.sortedStudies.push newStudyName
        window.fg.mindmap.data.studies[newStudyName] = {
          data: {
            weight: newStudyWeight
          },
          years: {}
        }

        # Create and add the new study to the interface.
        window.fg.mindmap.studySelect.appendChild new Option(newStudyName, newStudyWeight - 1)

        item = document.createElement "div"
        item.classList.add "study-row"
        item.setAttribute "data-study", newStudyName

        name = document.createElement "span"
        name.className = "study-name"
        name.innerHTML = newStudyName
        item.appendChild name

        years = document.createElement "span"
        years.className = "study-year-count"
        years.innerHTML = "0 studiejaren"
        item.appendChild years

        item.addEventListener "click", (e) =>
          openStudyListener(e)

        studiesColumn.insertBefore item, addStudyButton

    studiesColumn.appendChild addStudyButton

    # Create the right column containing the study details.
    detailsColumn = document.createElement "div"
    detailsColumn.id = "details-column"
    detailsColumn.innerHTML = "<h3 id='placeholder-text'>Selecteer een studie om deze te bewerken</h3>"
    studiesEditorContainer.appendChild detailsColumn

    # The close-handler to close the editor.
    removeEditor = () =>
      document.querySelector("#content").removeChild studiesEditorContainer
      window.fg.mindmap.removeOverlay()

    # The close-button in the top right.
    closeButton = document.createElement "i"
    closeButton.id = "study-editor-close-button"
    closeButton.className = "far fa-times-circle"
    closeButton.addEventListener "click", removeEditor
    studiesEditorContainer.appendChild closeButton

    # Show the popup and overlay.
    document.querySelector("#content").appendChild studiesEditorContainer
    window.fg.mindmap.showOverlay(removeEditor)

    studiesEditorOpen = false

    this

  # Creates a popup with an HTML WYSIWYG editor
  # to allow for rich text input.
  wysiwygEditorOpen = false
  createWYSIWYGEditor: (value, editorCallback) ->
    if wysiwygEditorOpen
      return

    wysiwygEditorOpen = true

    # Create the popup-container to hold everything.
    wysiwygContainer = document.createElement "div"
    wysiwygContainer.id = "wysiwyg-container"
    wysiwygContainer.className = "no-drag"
    wysiwygContainer.style.display = "none"
    document.querySelector("#content").appendChild wysiwygContainer

    # Create and initialze the WYSIWYG editor.
    editor = document.createElement "div"
    editor.id = "wysiwyg-editor"
    wysiwygContainer.appendChild editor

    options = {
      placeholder: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      theme: "snow"
    };
    editor = new Quill('#wysiwyg-editor', options)
    if value
      editor.root.innerHTML = value;

    # Callback to save the value and
    removeContainer = () =>
      editorCallback(editor.root.innerHTML)
      document.querySelector("#content").removeChild wysiwygContainer
      wysiwygEditorOpen = false

    # Create the save button.
    saveButton = document.createElement "button"
    saveButton.id = "wysiwyg-save-button"
    saveButton.innerHTML = "Opslaan <i class='fas fa-save'></i>"
    saveButton.addEventListener "click", () =>
      removeContainer()
      window.fg.mindmap.removeOverlay()
    wysiwygContainer.appendChild saveButton

    # Show the overlay.
    window.fg.mindmap.showOverlay(removeContainer)

    # And actually display the WYSIWYG editor.
    wysiwygContainer.style.display = "block"

    this

  # Creates a block-item to hold a bunch of related fields.
  createInputBlock: (name) ->

    # The container to hold everything.
    block = document.createElement "div"
    block.className = "editor-item"

    # The bold title of the item.
    title = document.createElement "label"
    title.className = "title"
    title.innerHTML = name
    block.appendChild title

    return block

  # Builds the HTML for an editor-entry.
  createItem: (name, value) ->

    # The container to hold everything.
    @block = @createInputBlock(NORMALIZED_NAMES[name])

    # Add the appropriate input.
    @addInputFields(name, value)

    this

  # Routes the propertie to the right input-field creating method.
  addInputFields: (name, value) ->
    if name in Object.keys(PROPERTY_TYPES)
      @["#{PROPERTY_TYPES[name]}InputCreate"](name, value)
    this

  # Adds the newly built block to the editor.
  addToEditor: () ->
    @editorContent.appendChild @block
    this

  # Listens for any changes made in the editor to automatically
  # reflect those changes in the view.
  listenForChanges: () ->
    for field in @editorContent.querySelectorAll ".property"
      field.addEventListener "change", (event) =>
        property = event.target.getAttribute("data-property")
        @updateProperty(property)
        return

    for field in @editorContent.querySelectorAll ".array-property"
      @makeRichTextInput(field, (value) -> field.value = value)
      field.addEventListener "change", (event) =>
        property = event.target.getAttribute("data-property")
        @updateArrayProperty(property)
        return
    this

  # Updates a single property.
  updateProperty: (property) ->
    if property.split("_").length > 1
      @node.nodeData[property.split("_")[0]][property.split("_")[1]] = event.target.value
    else
      @node.nodeData[property] = event.target.value
    @node.build().addListeners().rerender()

    this

  # Updates a property consisting of an array of values,
  # such as the theorems.
  updateArrayProperty: (property) ->
    new_values = []
    for entry in @editorContent.querySelectorAll "input[data-property='#{property}']"
      new_values.push(entry.value)
    if property.split("_").length > 1
      @node.nodeData[property.split("_")[0]][property.split("_")[1]] = new_values
    else
      @node.nodeData[property] = new_values
    @node.build().addListeners().rerender()

    this

  # Disables default browser behaviour for this input to instead
  # open up the WYSIWYG editor.
  makeRichTextInput: (input, callback) ->
    input.addEventListener "click", (e) =>
      e.preventDefault()
      @createWYSIWYGEditor(tagCleanup(input.value), (value) =>
        callback(tagCleanup(value))
        input.dispatchEvent new Event("change"))
      document.querySelector(".ql-editor").focus()
      false
    this

  # Creates a simple text-field input.
  textInputCreate: (name, value) ->
    input = document.createElement "input"
    input.type = "text"
    input.id = "property-#{name}"
    input.className = "property"
    input.setAttribute("data-property", name)
    input.value = value
    @makeRichTextInput(input, (value) -> input.value = value)

    @block.appendChild input

    this

  # Creates a multiline text-field input.
  multilinetextInputCreate: (name, value) ->
    input = document.createElement "textarea"
    input.id = "property-#{name}"
    input.className = "property"
    input.setAttribute("data-property", name)
    input.value = value
    @makeRichTextInput(input, (value) -> input.value = value)

    @block.appendChild input

    this

  # Creates a standard number-input.
  numberInputCreate: (name, value) ->
    input = document.createElement "input"
    input.type = "number"
    input.id = "property-#{name}"
    input.className = "property"
    input.setAttribute("data-property", name)
    input.value = value

    @block.appendChild input

    this

  # Creates an HTML5 color-input.
  colorInputCreate: (name, value) ->

    hexBlock = document.createElement "div"
    hexBlock.className = "hexblock"

    hexBefore = document.createElement "div"
    hexBefore.className = "hexbefore"
    hexBefore.innerHTML = "#"
    hexBlock.appendChild hexBefore

    hexInput = document.createElement "input"
    hexInput.type = "text"
    hexInput.className = "hexinput"
    hexInput.value = value.substr(1)
    hexBlock.appendChild hexInput

    colorInput = document.createElement "input"
    colorInput.type = "color"
    colorInput.id = "property-#{name}"
    colorInput.className = "property"
    colorInput.setAttribute("data-property", name)
    colorInput.value = value

    hexInput.addEventListener "change", () ->
      colorInput.value = "##{hexInput.value}"
      colorInput.dispatchEvent new Event("change")
    colorInput.addEventListener "change", () ->
      hexInput.value = colorInput.value.substr(1)

    @block.appendChild hexBlock
    @block.appendChild colorInput

    this

  # Creates multiple text inputs for properties that
  # consist of multiple values, such as the theorems.
  multitextInputCreate: (name, values) ->

    # Add all existing items as input blocks.
    for value in values

      inputBlock = document.createElement "div"
      inputBlock.className = "inputblock"

      input = document.createElement "input"
      input.type = "text"
      input.className = "array-property"
      input.setAttribute("data-property", name)
      input.value = value
      inputBlock.appendChild input

      removeButton = document.createElement "i"
      removeButton.className = "removeButton far fa-trash-alt"
      inputBlock.appendChild removeButton
      removeButton.addEventListener "click", (event) =>
        event.target.parentElement.parentElement.removeChild event.target.parentElement
        @updateArrayProperty(name)

      @block.appendChild inputBlock

    # Add the 'add'-button.
    addButton = document.createElement "button"
    addButton.className = "add-button"
    addButton.innerHTML = "Toevoegen <i class='fas fa-plus-square'></i>"
    addButton.addEventListener "click", () =>
      inputBlock = document.createElement "div"
      inputBlock.className = "inputblock"

      input = document.createElement "input"
      input.type = "text"
      input.className = "array-property"
      input.setAttribute("data-property", name)
      input.value = ""
      inputBlock.appendChild input
      input.addEventListener "change", (event) =>
        @updateArrayProperty(name)

      removeButton = document.createElement "i"
      removeButton.className = "removeButton far fa-trash-alt"
      inputBlock.appendChild removeButton

      @block.insertBefore inputBlock, addButton
      input.focus()

    @block.appendChild addButton

    this

  # Creates a special input for video-urls that is capable
  # of automatically detecting supported video platforms.
  videourlInputCreate: (name, value) ->
    input = document.createElement "input"
    input.type = "text"
    input.id = "property-#{name}"
    input.className = "property"
    input.setAttribute("data-property", name)
    input.value = value

    @block.appendChild input

    # The open-in URL.
    openInUrl = document.createElement "a"
    openInUrl.className = "platform-url"
    openInUrl.href = value
    openInUrl.target = "_blank"
    openInUrl.innerHTML = "Open in "
    if value.length == 0
      openInUrl.style.display = "none"

    platformLogo = document.createElement "i"
    platformLogo.className = "fab fa-#{@node.nodeData.data.type}"
    openInUrl.appendChild platformLogo

    @block.appendChild openInUrl

    # The URL parsing.
    input.addEventListener "change", (event) =>
      parser = document.createElement "a"
      parser.href = input.value
      validURL = false

      # Parse Youtube URLs.
      if parser.hostname == "www.youtube.com" or parser.hostname == "youtube.com"
        @node.nodeData.data.type = "youtube"
        if parser.pathname.startsWith "/watch"
          elements = parser.search.split("&")[0].split("=")
          if elements[0] == "?v"
            videoID = elements[1]
            input.value = "https://www.youtube.com/embed/#{videoID}"
            openInUrl.href = "https://www.youtube.com/watch?v=#{videoID}"
            platformLogo.className = "fab fa-youtube"
            validURL = true

      # Parse Google Drive URLs.
      else if parser.hostname == "www.drive.google.com" or parser.hostname == "drive.google.com"
        @node.nodeData.data.type = "google-drive"
        if parser.pathname.startsWith "/file/d/"
          videoID = parser.pathname.replace("/file/d/", "").split("/")[0]
          input.value = "https://drive.google.com/file/d/#{videoID}/preview"
          openInUrl.href = "https://drive.google.com/file/d/#{videoID}/view"
          platformLogo.className = "fab fa-google-drive"
          validURL = true

      if !validURL
        window.fg.sidemenu.errorMessage("Ongeldige video link")
        event.stopPropagation()

    this

  # Create an up- and down-buttons to adjust the horizontal position of a node
  # and left- and right-buttons to move rootnodes to a different side.
  positionInputCreate: (name, value) ->

    siblings = @node.targetParent.querySelectorAll("li.child-item")
    currentIndex = 1 + Array.prototype.indexOf.call(siblings, @node.html)
    maxWeight = siblings.length

    upButton = document.createElement "button"
    upButton.className = "vertical-position-button"
    upButton.innerHTML = "<span>Omhoog</span> <i class='fas fa-sort-up'></i>"
    upButton.disabled = true if currentIndex == 1
    @block.appendChild upButton

    downButton = document.createElement "button"
    downButton.className = "vertical-position-button"
    downButton.innerHTML = "<span>Omlaag</span> <i class='fas fa-sort-down'></i>"
    downButton.disabled = true if currentIndex == maxWeight
    @block.appendChild downButton

    upButton.addEventListener "click", (event) =>
      currentIndex -= 1
      @node.targetParent.insertBefore(@node.html, @node.html.previousElementSibling)
      @node.nodeData.weight = currentIndex


      if currentIndex == 1
        upButton.disabled = true
      else
        upButton.disabled = false

      if currentIndex == maxWeight
        downButton.disabled = true
      else
        downButton.disabled = false

    downButton.addEventListener "click", (event) =>
      currentIndex += 1
      @node.targetParent.insertBefore(@node.html.nextElementSibling, @node.html)
      @node.nodeData.weight = currentIndex

      if currentIndex == 1
        upButton.disabled = true
      else
        upButton.disabled = false

      if currentIndex == maxWeight
        downButton.disabled = true
      else
        downButton.disabled = false

    if @node.isRootNode

      leftButton = document.createElement "button"
      leftButton.className = "horizontal-position-button"
      leftButton.innerHTML = "<i class='fas fa-caret-left'></i> Links"
      leftButton.disabled = true if @node.nodeData.side == "left"
      @block.appendChild leftButton

      rightButton = document.createElement "button"
      rightButton.className = "horizontal-position-button"
      rightButton.innerHTML = "Rechts <i class='fas fa-caret-right'></i>"
      rightButton.disabled = true if @node.nodeData.side == "right"
      @block.appendChild rightButton

      leftButton.addEventListener "click", (event) =>
        if @node.html.querySelector(".chevron")
          @node.html.querySelector(".chevron").classList.replace "right", "left"
        @node.nodeData.side = "left"
        @node.targetParent = document.querySelector("#leftbranch")
        document.querySelector("#leftbranch").appendChild @node.html
        leftButton.disabled = true
        rightButton.disabled = false

      rightButton.addEventListener "click", (event) =>
        if @node.html.querySelector(".chevron")
          @node.html.querySelector(".chevron").classList.replace "left", "right"
        @node.nodeData.side = "right"
        @node.targetParent = document.querySelector("#rightbranch")
        document.querySelector("#rightbranch").appendChild @node.html
        leftButton.disabled = false
        rightButton.disabled = true

    this

  # Creates the drop-down that can be used to switch the type of the node
  # to a different type. On switching, it clears the node data.
  nodetypeInputCreate: () ->

    # The currently supported node-types.
    types = [["text", "Tekst"],
             ["video", "Video"],
             ["checklist", "Checklist"]]

    dropdownContainer = document.createElement "span"
    dropdownContainer.className = "dropdown editor-dropdown"
    dropdown = document.createElement "select"
    dropdownContainer.appendChild dropdown

    for type in types
      option = document.createElement "option"
      option.value = type[0]
      option.innerHTML = type[1]
      dropdown.appendChild option

    dropdown.value = @node.nodeData.type
    @block.appendChild dropdownContainer

    # Bind the eventlistener to the dropdown to change the
    # node type when a different option is selected.
    dropdown.addEventListener "change", (event) =>


      # Get the relevant properties from the old node.
      targetParent = @node.targetParent
      id = @node.html.id
      nodeData = @node.nodeData
      isRootNode = @node.isRootNode

      # Set the data-property based on the new node type.
      newType = event.target.value
      if newType == "text"
        nodeData.data = {
          text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        }
      else if newType == "video"
        nodeData.data = {
          type: "youtube",
          url: "https://www.youtube.com/embed/NpEaa2P7qZI",
          text: "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
        }
      else if newType == "checklist"
        nodeData.data = {
          theorems: [
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
          ],
          feedback: {
            "50": "Lorem ipsum dolor sit amet, consectetur adipisicing elit"
          }
        }

      nodeData.type = newType

      # Delete the relation with the parent.
      if isRootNode
        window.fg.mindmap.mindmapData.nodes = window.fg.mindmap.mindmapData.nodes.filter (rootnode) =>
          rootnode != @node.nodeData
      else
        @node.nodeData.parentObject.nodeData.children = @node.nodeData.parentObject.nodeData.children.filter (child) =>
          child != @node.nodeData

      # Delete the existing node.
      @node = null

      # Create the new node, set some properties back and render it.
      @node = new supportedNodeTypes[newType](nodeData, isRootNode)
      @node.targetParent = targetParent
      @node.build()
      @node.html.id = id
      @node.addListeners().rerender()

      # Add the node back to the parent.
      if isRootNode
        window.fg.mindmap.mindmapData.nodes.push @node.nodeData
      else
        @node.nodeData.parentObject.nodeData.children.push @node.nodeData

    this

  # Creates two buttons to add and remove nodes.
  # Prevents the user from removing all nodes.
  addRemoveButtonCreate: () ->
    # The container to hold the buttons.
    @block = @createInputBlock("Node")

    addButton = document.createElement "button"
    addButton.className = "node-add-button"
    addButton.innerHTML = "Extra node toevoegen <i class='fas fa-plus-square'></i>"
    @block.appendChild addButton

    if @node.isRootNode
      addRootButton = document.createElement "button"
      addRootButton.className = "node-add-root-button"
      addRootButton.innerHTML = "Extra root node toevoegen <i class='fas fa-plus-square'></i>"
      @block.appendChild addRootButton

    removeButton = document.createElement "button"
    removeButton.className = "node-remove-button"
    removeButton.innerHTML = "Node verwijderen <i class='far fa-trash-alt'></i>"
    removeButton.disabled = (document.querySelectorAll(".node").length <= 1)
    @block.appendChild removeButton

    # Adding a new child-node.
    addButton.addEventListener "click", (event) =>
      newNode = {
        children: [],
        color: "#6b2565",
        data: {
          text: "Lorem ipsum dolor"
        },
        messages: {
          open: "",
          close: ""
        },
        name: "Nieuwe node...",
        type: "text",
        weight: @node.nodeData.children.length
      }

      @node.nodeData.children.push newNode

      if !@node.expanded
        if @node.nodeData.children.length == 1
          @node.addExpandButton()
        @node.html.querySelector(".node-expand").classList.toggle "active"
        @node.expanded = true
        @node.expandChildren()
      else
        newRenderedNode = new TextNode(newNode)
        newRenderedNode.nodeData.parent = @node.html
        newRenderedNode.build().addListeners().render()

    # Adding another root-node.
    if @node.isRootNode
      addRootButton.addEventListener "click", (event) =>
        newNode = {
          children: [],
          color: "#6b2565",
          data: {
            text: "Lorem ipsum dolor"
          },
          messages: {
            open: "",
            close: ""
          },
          name: "Nieuwe node...",
          side: @node.nodeData.side,
          type: "text",
          weight: @node.nodeData.children.length
        }
        window.fg.mindmap.mindmapData.nodes.push newNode

        newRenderedNode = new TextNode(newNode, true)
        newRenderedNode.build().addListeners().render()

    # Removing the current node.
    removeButton.addEventListener "click", (event) =>
      if !@node.isRootNode

        # Remove the parents link to this node.
        @node.nodeData.parentObject.nodeData.children = @node.nodeData.parentObject.nodeData.children.filter (child) =>
          child != @node.nodeData
        @node.html.parentNode.removeChild @node.html

        # Explicitly signal the garbage collector to clean this node and its nested children.
        @node = null

        # Reset the sidemenu content.
        window.fg.sidemenu.reset()
      else

        # Prevent deletion of the last rootnode.
        if document.querySelectorAll(".root-child").length == 1
          window.fg.sidemenu.errorMessage("De laatste root-node kan niet verwijderd worden")
        else
          window.fg.mindmap.mindmapData.nodes = window.fg.mindmap.mindmapData.nodes.filter (rootnode) =>
            rootnode != @node.nodeData
          @node.html.parentNode.removeChild @node.html

          # Reset the sidemenu content.
          window.fg.sidemenu.reset()

    this

