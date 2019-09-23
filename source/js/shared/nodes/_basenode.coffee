# Used to give unique IDs to all nodes.
nodeCounter = 0

# Implements the basic methods and interface for every type of node.
# Provides dynamic node construction, eventlisteners and the basic
# behaviour of every node.
class BaseNode

  # Keeps track of external clicklisteners that can subscribe
  # to click-events on this node, such as the editor.
  @externalClickListeners = []

  # Sets the basic properties of the node.
  constructor: (@nodeData, @isRootNode = false) ->

  ### PUBLIC METHODS ###

  # Builds the basic DOM node-object on which all types of nodes
  # are based.
  build: () ->
    @createDOMElement()
    @expanded = false
    this

  # Renders the created node by appending it to the DOM.
  render: () ->
    if @isRootNode
      @targetParent = document.getElementById "#{@nodeData.side}branch"
    else
      @targetParent = @nodeData.parent.querySelector ".children.nested"

    @targetParent.appendChild @html

    @nodeData.element = @html

    @setNodeSize()
    this

  # Renders the node with an slide-in animation.
  renderAnimated: () ->
    @html.classList.add "animate-in"
    @render()
    this

  # Re-renders the node in its current location.
  rerender: () ->
    pageNode = @targetParent.querySelector "##{@html.id}"
    node = pageNode.querySelector(".node")
    wasOpened = false

    swapContents = () =>

      # Transfer classes and contents.
      if pageNode.querySelector(".node-expand")
        @html.querySelector(".node-expand").className = pageNode.querySelector(".node-expand").className

      @html.removeChild @html.querySelector ".children.nested"
      @html.appendChild pageNode.querySelector ".children.nested"

      pageNode.className = @html.className
      @html.querySelector(".node").className = pageNode.querySelector(".node").className
      pageNode.innerHTML = ""
      pageNode.appendChild @html.querySelector ".node"
      pageNode.appendChild @html.querySelector ".children.nested"

      @html = pageNode
      @setNodeSize()
      @activateNode(@html.querySelector(".node")) if wasOpened

    if node.classList.contains "active"
      wasOpened = true
      transitionEnd = () ->
        node.removeEventListener "transitionend", transitionEnd
        swapContents()

      node.addEventListener "transitionend", transitionEnd
      @deactivateNode(node)
    else
      swapContents()

    this

  # Binds all required listeners for this node.
  # The listeners pass on the events to the right event-handler method.
  addListeners: () ->
    @html.removeEventListener "click", @clickListener
    @html.addEventListener "click", @clickListener

    @bindHoverListeners()
    @bindExpansionHandler() if @nodeData.children and @nodeData.children.length
    this

  # Places focus on this node by moving it to the center.
  focus: () ->
    expandButton = @html.querySelector ".node-expand"
    focusX = Math.ceil(document.getElementById("content").offsetWidth / 2 - expandButton.offsetWidth / 2)
    focusY = Math.ceil(document.getElementById("content").offsetHeight / 2 - expandButton.offsetHeight / 2)
    moveX = focusX - expandButton.getBoundingClientRect().left
    moveY = focusY - expandButton.getBoundingClientRect().top
    fg.mindmap.animation.moveRelative(moveX, moveY, 500)
    this

  # Removes focus from this node by focussing on its parent-node.
  blur: () ->
    if @isRootNode
      fg.mindmap.moveToCenter()
    else
      focusAnimation = new Animation(document.querySelector "#mindmap")
      expandButton = @nodeData.parent.querySelector ".node-expand"
      focusX = Math.ceil(document.getElementById("content").offsetWidth / 2 - expandButton.offsetWidth / 2)
      focusY = Math.ceil(document.getElementById("content").offsetHeight / 2 - expandButton.offsetHeight / 2)
      moveX = focusX - expandButton.getBoundingClientRect().left
      moveY = focusY - expandButton.getBoundingClientRect().top
      fg.mindmap.animation.moveRelative(moveX, moveY, 500)
    this

  # Adds the expand-button if the node didn't have one yet.
  addExpandButton: () ->
    @html.querySelector(".node-content").appendChild @buildExpandButton()
    @bindExpansionHandler()

  ### PRIVATE METHODS ###

  # Opens the node to show its full contents.
  activateNode: (node) ->

    node.classList.add "active"
    target = node.querySelector ".node-content"

    # Focus the screen on the opening node if the node is too
    # far off center.
    contentWidth = document.getElementById("content").offsetWidth
    contentHeight = document.getElementById("content").offsetHeight
    nodeRect = target.getBoundingClientRect()

    if (nodeRect.x + nodeRect.width) > 0.75 * contentWidth or
       (nodeRect.y + nodeRect.height) > 0.75 * contentHeight or
       (nodeRect.x < 0.25 * contentWidth) or
       (nodeRect.y < 0.25 * contentHeight)
      targetX = contentWidth / 2 - nodeRect.width / 2
      targetY = contentHeight / 2 - nodeRect.height / 2
      moveX = targetX - nodeRect.left
      moveY = targetY - nodeRect.top

      fg.mindmap.animation.moveRelative(moveX, moveY, 500)

    # Open the new node.
    @originalHeight = getOuterHeight target
    activeContentHeight = getOuterHeight target.getElementsByClassName("node-active-content")[0]
    node.style.height = "#{@originalHeight + activeContentHeight}px"

    # If set, show the open-message.
    if @nodeData.messages.open and @nodeData.messages.open.length > 0
      message = document.createElement "span"
      message.className = "textBubbleContent standard"
      message.innerHTML = @nodeData.messages.open
      fg.mindmap.updateTextBubbleContent message

  # Closes the node to go back to its original height.
  deactivateNode: (node) ->
    node.classList.remove "active"
    node.style.height = "#{@originalHeight}px"
    @originalHeight = 0

    # If set, show the close-message.
    if @nodeData.messages.close and @nodeData.messages.close.length > 0
      message = document.createElement "span"
      message.className = "textBubbleContent standard"
      message.innerHTML = @nodeData.messages.close
      fg.mindmap.updateTextBubbleContent message

  # Expands or minimizes the node on a user-click.
  # Can be extended by inheriting classes to handle click-events
  # with other purposes.
  onClickEvent: (event) ->

    # Skip actions on elements that have non-default actions, such as checkboxes.
    return if recursiveHasClass event.target, "prevent-default"

    # Skip actions on elements that by default have their own actions,
    # such as links and buttons.
    return if ["A", "BUTTON"].includes event.target.tagName

    target = event.target.closest ".node-content"

    # Skip if the node itself wasn't clicked.
    return if target is null

    node = target.closest ".node"

    # Toggle the size of the node.
    if node.classList.contains "active"
      @deactivateNode(node)
    else
      @activateNode(node)
    return

  # Creates the basic DOM element on which every node is based
  # and stores it in @html.
  createDOMElement: () ->
    if typeof @html != "undefined"
      nodeID = @html.id
    else
      nodeID = "node-#{nodeCounter++}"

    # Create all HTML elements.
    nodeContainer = document.createElement "li"
    nodeContainer.id = nodeID
    nodeContainer.classList.add "child-item"
    if @isRootNode
      nodeContainer.classList.add "root-child"

    node = document.createElement "div"
    node.classList.add "node", "no-drag"
    node.style.backgroundColor = @nodeData.color

    contentContainer = document.createElement "div"
    contentContainer.classList.add "node-content-container"

    header = document.createElement "div"
    header.classList.add "node-content-header"

    content = document.createElement "div"
    content.classList.add "node-content"

    name = document.createElement "div"
    name.classList.add "node-name"
    name.innerHTML = @nodeData.name
    cleanedName = document.createElement "div"
    cleanedName.innerHTML = @nodeData.name
    name.style.width = "#{measureTextWidth cleanedName.innerText}px"

    activeContent = document.createElement "div"
    activeContent.classList.add "node-active-content"

    childrenContainer = document.createElement "ol"
    childrenContainer.classList.add "children", "nested"

    # Add the expand-arrow for child-nodes.
    if @nodeData.children and @nodeData.children.length
      content.appendChild @buildExpandButton()

    # Style the colored lines that run to the node.
    target = "##{nodeID}.child-item,#leftbranch ##{nodeID}.child-item:before,#rightbranch ##{nodeID}.child-item:before"
    rule = "border-color: " + @nodeData.color
    #if navigator.userAgent.toLowerCase().indexOf("firefox") > -1
    #  document.styleSheets[0].insertRule("#{target} {#{rule}}")
    #else
    document.styleSheets[0].addRule(target, rule)

    # Add the open/close arrow.
    arrow = document.createElement "div"
    arrow.classList.add "node-arrow"

    chevron = document.createElement "i"
    chevron.classList.add "fa", "fa-chevron-right"

    arrow.appendChild chevron

    # Put all the HTML elements together.
    header.appendChild name
    header.appendChild arrow
    contentContainer.appendChild header
    contentContainer.appendChild activeContent
    content.appendChild contentContainer
    node.appendChild content
    nodeContainer.appendChild node
    nodeContainer.appendChild childrenContainer

    @html = nodeContainer
    return

  # The click-listener which filters out events for child-nodes
  # and passes the event to the @onClickEvent and optional
  # external event listeners.
  clickListener: (event) =>
    childContainer = @html.querySelector ".children.nested"

    # Filter out any events on children of this node.
    if not isDescendant event.target, childContainer

      blockedByExternalListener = false

      # Notify all external clicklisteners, such as the editor.
      if @externalClickListeners
        for externalListener in @externalClickListeners
          blockedByExternalListener |= externalListener(this, event)

      # And then notify the internal listener.
      if not blockedByExternalListener
        @onClickEvent(event)

  # Binds the hover-listeners used for visual indications
  # such as the striped border.
  bindHoverListeners: () ->
    node = @html.querySelector ".node"
    container = @html.querySelector ".node-content-container"
    expandButton = @html.querySelector ".node-expand"

    # The hover-effect on the node itself.
    container.addEventListener "mouseover", () =>
      node.classList.add "hover"
    container.addEventListener "mouseout", () =>
      node.classList.remove "hover"

    # The hover-effect on the expand-button.
    if expandButton
      expandButton.addEventListener "mouseover", () =>
        expandButton.classList.add "hover"
      expandButton.addEventListener "mouseout", () =>
        expandButton.classList.remove "hover"

  # Binds the expansionhandler that allows the user to expand
  # a sub-branch of this node and see it's child-nodes.
  bindExpansionHandler: () ->
    expandButton = @html.querySelector ".node-expand"

    expandButton.addEventListener "click", (event) =>

      # Toggle the child-container.
      expandButton.classList.toggle "active"
      @expanded = !@expanded

      if @expanded
        @expandChildren()
      else
        @collapseChildren()

      return

  # Expands the child-nodes of the node.
  expandChildren: () ->

    sortedChildren = @nodeData.children.sort (a,b) ->
      return 1 if (a.weight > b.weight)
      return -1 if (a.weight < b.weight)
      return 0

    for child in sortedChildren

      # Extend the child-node with data from the parent-node.
      child.parent = @html
      child.parentObject = this
      child.side = @nodeData.side

      childNode = new supportedNodeTypes[child.type](child)
      childNode.build().addListeners().renderAnimated()

    # Place focus on the node.
    @focus()

  # Collapse the child-nodes of the node.
  collapseChildren: () ->
    childContainer = @html.querySelector ".children.nested"

    children = childContainer.querySelectorAll(".child-item")
    for child, index in children
      child.classList.add "animate-out"
      if index == children.length - 1
        child.addEventListener "animationend", () ->
          childContainer.innerHTML = ""

    # Place focus on the node's parent.
    @blur()

  # Sets the node-width correctly in absolute number of pixels so that the hover-border
  # has the correct size.
  # Not the most beautiful solution, but this can't be calculated in the build-function
  # since the browser doesn't know the real size of an element until its rendered.
  setNodeSize: () ->
    @html.querySelector(".node").style.width = "#{@html.querySelector(".node-content-container").offsetWidth}px"

  # Simply builds and returns the HTML element for the expand-button
  # so it can be appended to the node.
  buildExpandButton: () ->
    # Create the HTML elements.
    nodeExpand = document.createElement "div"
    nodeExpand.classList.add "node-expand", "prevent-default"
    nodeExpand.style.backgroundColor = @nodeData.color

    chevron = document.createElement "div"
    chevron.classList.add "chevron", @nodeData.side

    pipe = document.createElement "div"
    pipe.classList.add "pipe"

    # And combine them.
    nodeExpand.appendChild chevron
    nodeExpand.appendChild pipe

    return nodeExpand

