WIDTH = 800
HEIGHT = 600
SHIP_POSY = HEIGHT - 60

class ShipShot
  width: 2
  height: 20

  elem: ->
    $('#ship-shot')

  constructor: (@posx) ->
    @posy = SHIP_POSY
    $.playground().addSprite('ship-shot',
      posx: @posx,
      posy: @posy,
      width: @width,
      height: @height,
      animation: new $.gQ.Animation(imageURL: "images/ship-shot.jpg"))

  updatePos: ->
    if @posy > 0
      @posy -= 20
      @elem().y(@posy)
      @
    else
      @destroy()

  destroy: ->
    @elem().remove()
    null

  rect: ->
    {top: @posy, left: @posx, bottom: @posy + @height, right: @posx + @width}

class AlienShot
  width: 2
  height: 20

  elem: ->
    $('#alien-shot')

  constructor: (@posx, @posy) ->
    $.playground().addSprite('alien-shot',
      posx: @posx,
      posy: @posy,
      width: @width,
      height: @height,
      animation: new $.gQ.Animation(imageURL: "images/ship-shot.jpg"))

  updatePos: ->
    if @posy < HEIGHT
      @posy += 10
      @elem().y(@posy)
      @
    else
      @destroy()

  destroy: ->
    @elem().remove()
    null

  rect: ->
    {top: @posy, left: @posx, bottom: @posy + @height, right: @posx + @width}


class Ship
  constructor: (args) ->

  posx: 0
  width: 63
  height: 40

  elem: ->
    $('#ship')

  animation: ->
    new $.gQ.Animation(imageURL: "images/space-invaders-ship1.jpg")

  spriteData: ->
    posx: @posx, posy: SHIP_POSY, height: @height, width: @width, animation: @animation()

  moveRight: ->
    @posx += 5 if @posx < WIDTH
    @updatePos()

  moveLeft: ->
    @posx -= 5 if @posx > 0
    @updatePos()

  updatePos: ->
    @elem().x(@posx)

  fire: ->
    new ShipShot(@posx + @width / 2)

  collidesWith: (rect) ->
    SHIP_POSY <= rect.bottom && SHIP_POSY + @height >= rect.top &&
    @posx <= rect.right  && @posx + @width  >= rect.left

alienId = 0
class Alien
  width: 40
  height: 30

  constructor: (@posx, @posy, @type) ->
    @id = (alienId += 1)
    rate = 100 + 200 * Math.random()
    $.playground().addSprite("alien-#{@id}",
      posx: @posx,
      posy: @posy,
      width: @width,
      height: @height,
      animation: new $.gQ.Animation(imageURL: "images/invader#{@type}.jpg", numberOfFrame: 4, delta: 30, rate: rate, type: $.gameQuery.ANIMATION_VERTICAL))

  elem: ->
    $("#alien-#{@id}")

  moveHoriz: (deltax) ->
    @posx += deltax
    @updatePos()

  moveVert: (deltay) ->
    @posy += deltay
    @updatePos()

  updatePos: ->
    @elem().x(@posx).y(@posy)

  collidesWith: (rect) ->
    @posy <= rect.bottom && @posy + @height >= rect.top &&
    @posx <= rect.right  && @posx + @width  >= rect.left

  destroy: ->
    @elem().fadeOut 500, ->
      @elem().remove()
    # @elem().toggle 'explode'
    #, 1000, ->
    #  @remove()

  fire: ->
    new AlienShot(@posx + @width / 2, @posy + @height)

aliens = []
class AlienManager
  type: 0

  generujRzadekAlienow: (num) ->
    @type += 1
    for x in [0..9]
      aliens.push new Alien(20 + x * 60, 20 + num * 40, @type % 3)

  destroy: (a) ->
    a.destroy()
    aliens.splice(aliens.indexOf(a), 1)

am = new AlienManager

ship = new Ship
shipShot = null

shipCallback = ->
  if $.gameQuery.keyTracker[37] # left arrow
    ship.moveLeft()
  if $.gameQuery.keyTracker[39] # right arrow
    ship.moveRight()
  if $.gameQuery.keyTracker[32] # space
    unless shipShot
      shipShot = ship.fire()

alienShot = null
shotCallback = ->
  if shipShot
    shipShot = shipShot.updatePos()
    for alien in aliens
      if alien.collidesWith(shipShot.rect())
        am.destroy(alien)
        shipShot = shipShot.destroy()
        break
  if alienShot
    alienShot = alienShot.updatePos()
    if alienShot && ship.collidesWith(alienShot.rect())
      gameOver()

gameOver = ->
  $.playground().pauseGame()
  $('#game-over-screen').fadeIn(2000)

aliensDelta = 5
alienSteps = 0
alienStepsDown = 0
aliensFireRate = 0.01
alienCallbackRate = 150
alienCallback = ->
  for alien in aliens
    alien.moveHoriz(aliensDelta)
    if !alienShot && Math.random() < aliensFireRate
      alienShot = alien.fire()

  alienSteps += 1
  if alienSteps >= 30
    alienSteps = 0
    aliensDelta = -aliensDelta
    for alien in aliens
      alien.moveVert(10)
      if alien.posy >= SHIP_POSY
        gameOver()

    alienStepsDown += 1
    if alienStepsDown > 3
      alienStepsDown = 0
      aliensDelta += 1
      am.generujRzadekAlienow(0)
      aliensFireRate *= 1.1
      alienCallbackRate -= 10 # returned!

$ ->
  $("#startbutton").click ->
    $.playground().startGame ->
      $("#welcomeScreen").remove()

  $('#playground').playground(height: HEIGHT, width: WIDTH, keyTracker: true)
  $.playground().addSprite('ship', ship.spriteData())

  am.generujRzadekAlienow(5)
  am.generujRzadekAlienow(4)
  am.generujRzadekAlienow(3)
  am.generujRzadekAlienow(2)
  am.generujRzadekAlienow(1)
  am.generujRzadekAlienow(0)

  $.playground().registerCallback shipCallback, 15
  $.playground().registerCallback shotCallback, 10
  $.playground().registerCallback alienCallback, alienCallbackRate

