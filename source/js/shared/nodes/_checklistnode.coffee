# A simple checklist with progressbar to reflect on
# the number of checkboxes checked.
class ChecklistNode extends BaseNode

  # Extends the basic node-HTML with checklist-specific extra's.
  build: () ->

    # Create the base node-html.
    super()

    # And extend it to a checklist node.
    @html.classList.add("checklist")

    # Add the progressbar.
    progressbar = document.createElement "div"
    progressbar.classList.add "node-checklist-progressbar"

    bar = document.createElement "div"
    bar.classList.add "bar"

    progressbar.appendChild bar
    @html.querySelector(".node-content-container").appendChild progressbar

    # Add the actual checklist.
    checklist = document.createElement "ul"
    checklistID = @html.id

    target = "##{checklistID} .checkmark:after"
    rule = "border-style:solid!important;border-color:#{@nodeData.color}!important;border-image:initial!important;border-width: 0 3px 3px 0 !important;"
    if (navigator.userAgent.toLowerCase().indexOf('firefox') > -1)
      document.styleSheets[0].insertRule("#{target} {#{rule}}")
    else
      document.styleSheets[0].addRule(target, rule)

    for theorem in @nodeData.data.theorems
      item = document.createElement "li"
      item.classList.add "checkbox-item", "prevent-default"

      label = document.createElement "label"
      label.classList.add "container"
      label.innerHTML = theorem

      checkbox = document.createElement "input"
      checkbox.type = "checkbox"

      checkmark = document.createElement "div"
      checkmark.classList.add "checkmark", checklistID

      label.appendChild checkbox
      label.appendChild checkmark
      item.appendChild label
      checklist.appendChild item

    @html.querySelector(".node-active-content").appendChild checklist

    return this

  # Adds eventlisteners for the checkboxes that update the progressbar
  # when the user checks one or more checkboxes.
  onClickEvent: (event) ->

    # Process normal click-events first.
    super(event)

    # Skip the event if this is no checkbox.
    return if not recursiveHasClass event.target, "checkbox-item"

    target = event.target
    parent = target.closest ".node"
    bar = parent.querySelector ".bar"

    # Calculate the percentage of checked checkboxes.
    checkedCheckboxes = parent.querySelectorAll("input[type='checkbox']:checked").length
    allCheckboxes = parent.querySelectorAll("input[type='checkbox']").length
    percentageChecked = Math.ceil(checkedCheckboxes / allCheckboxes * 100)

    # And update the progressbar.
    bar.style.width = "#{percentageChecked}%"

    # Assure the subtree is expanded if two or more
    # checkboxes are checked.
    if checkedCheckboxes >= 2
      expandButton = parent.querySelector ".node-expand"
      if expandButton && !(expandButton.classList.contains "active")
        expandButton.click()

    # Place optional feedback in the textbubble.
    for percentage in Object.keys(@nodeData.data.feedback).reverse()
      if percentageChecked >= percentage
        feedback = document.createElement "span"
        feedback.classList.add "textBubbleContent", "standard"
        feedback.innerHTML = @nodeData.data.feedback[percentage]
        fg.mindmap.updateTextBubbleContent feedback
        break





