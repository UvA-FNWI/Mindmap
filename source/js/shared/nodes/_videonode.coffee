class VideoNode extends BaseNode

  # Extends the basic node-HTML with videonode-specific extra's.
  build: () ->

    # Create the base node-html.
    super()

    @html.classList.add "video"

    # If set, add text to be displayed above the video.
    if @nodeData.data.text
      text = document.createElement "div"
      text.classList.add "text"
      text.innerHTML = @nodeData.data.text
      @html.querySelector(".node-active-content").appendChild text

    if @nodeData.data.url
      @open = false
      video = document.createElement "iframe"
      video.frameborder = 0
      video.setAttribute("allowfullscreen", "")
      video.setAttribute("mozallowfullscreen", "")
      video.setAttribute("msallowfullscreen", "")
      video.setAttribute("oallowfullscreen", "")
      video.setAttribute("webkitallowfullscreen", "")

      video.classList.add "frame"
      @html.querySelector(".node-active-content").appendChild video

    return this

  activateNode: () ->
    super(@html.querySelector(".node"))

    if !@open
      @html.querySelector("iframe").src = @nodeData.data.url
      @open = true


