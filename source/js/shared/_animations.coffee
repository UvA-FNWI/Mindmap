# Provides an easy way to animate movement of
# DOM objects.
class Animation

  # Sets the element to animate.
  constructor: (@element) ->
    @matrix = [
      1,    0,    0,   0,
      0,    1,    0,   0,
      0,    0,    1,   0,
      0,    0,    0,   1
    ]

  # Moving animation to move an element from a given position
  # to a target position over the course of 'durationMS' ms.
  move: (fromX, fromY, toX, toY, durationMS) ->
    steps = durationMS / 16
    curS = 0

    step = () =>
      curS += Math.PI / steps
      @matrix[12] += ((toX - fromX) / steps) * (Math.sin(curS) ** 2) * 2
      @matrix[13] += ((toY - fromY) / steps) * (Math.sin(curS) ** 2) * 2
      @updateTransformationMatrix()

      if curS < Math.PI
        requestAnimationFrame(step)
    requestAnimationFrame(step)

  # Moves an element relative to its current position.
  moveRelative: (moveX, moveY, duration) ->
    @move(@matrix[12], @matrix[13], @matrix[12] + moveX, @matrix[13] + moveY, duration)

  # Updates the scale factor of @element over the course
  # of 400ms.
  scale: (scale) ->
    steps = 400 / 16
    curS = 0

    step = () =>
      curS += Math.PI / steps
      @matrix[0] += (scale - @matrix[0]) / steps
      @matrix[5] += (scale - @matrix[0]) / steps
      @updateTransformationMatrix()

      if curS < Math.PI
        requestAnimationFrame(step)
    requestAnimationFrame(step)

  # Moves an element to a new position with the use
  # of an animationFrame.
  moveSingleFrame: (moveX, moveY) ->
    moveAnimation = () =>
      @matrix[12] += moveX
      @matrix[13] += moveY
      @updateTransformationMatrix()
    requestAnimationFrame(moveAnimation)

  # Updates the transformation matrix on @element.
  updateTransformationMatrix: () ->
    @element.style.transform = "matrix3d(" + @matrix.join(',') + ")"
