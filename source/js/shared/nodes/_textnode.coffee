class TextNode extends BaseNode

  # Extends the basic node-HTML with textnode-specific extra's.
  build: () ->

    # Create the base node-html.
    super()

    @html.classList.add "text"
    @html.querySelector(".node-active-content").innerHTML = @nodeData.data.text

    return this

