# Checks if the element or any of its parents has a specified class.
recursiveHasClass = (element, className) ->
  while element
    if element.classList and element.classList.contains className
      return true
    element = element.parentNode
  return false

# Returns the outerheight of an element.
getOuterHeight = (element) ->
  styles = window.getComputedStyle element
  margin = parseFloat(styles["marginTop"]) + parseFloat(styles["marginBottom"])
  Math.ceil element.offsetHeight + margin

# Checks if element a is a child of element b.
isDescendant = (a, b) ->
  node = a.parentNode
  while node != null
    if node is b
      return true
    node = node.parentNode
  return false

# Calculate the width of a given string
# using the invisible text-ruler element..
measureTextWidth = (text) ->
  ruler = document.querySelector("#text-ruler")
  ruler.innerHTML = text
  return ruler.offsetWidth

# Returns just the text of some html content.
getText = (html) ->
  block = document.createElement "div"
  block.innerHTML = html
  return block.innerText