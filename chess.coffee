# chess
fs = require("fs");
_ = require("underscore")

chess = {

  # an object containing all of my pieces. Will also need to load an object with oppPieces and check all those positions. 
  pieces: {};
  gameOver: false
  winner: ""

  #turn this into a loop for pawns of each color
  setPieces: ->
    for n in [1..8]
      id = "p#{n}"
      @pieces[id] = {id: "p#{n}", position: [n,2], color: "white", type: "pawn", firstMove: true}
    @pieces.r1 = {id: "r1", position: [1,1], color: "white", type: "rook"}
    @pieces.r2 = {id: "r2", position: [8,1], color: "white", type: "rook"}
    @pieces.k1 = {id: "k1", position: [2,1], color: "white", type: "knight"}
    @pieces.k2 = {id: "k2", position: [7,1], color: "white", type: "knight"}
    @pieces.b1 = {id: "b1", position: [3,1], color: "white", type: "bishop"}
    @pieces.b2 = {id: "b2", position: [6,1], color: "white", type: "bishop"}
    @pieces.q1 = {id: "q1", position: [5,1], color: "white", type: "queen"}
    @pieces.king1 = {id: "king1", position: [4,1], color: "white", type: "king"}
    for n in [9..16]
      id = "p#{n}"
      @pieces[id] = {id: "p#{n}", position: [n-8,7], color: "black", type: "pawn", firstMove: true}
    @pieces.r3 = {id: "r3", position: [1,8], color: "black", type: "rook"}
    @pieces.r4 = {id: "r4", position: [8,8], color: "black", type: "rook"}
    @pieces.k3 = {id: "k3", position: [2,8], color: "black", type: "knight"}
    @pieces.k4 = {id: "k4", position: [7,8], color: "black", type: "knight"}
    @pieces.b3 = {id: "b3", position: [3,8], color: "black", type: "bishop"}
    @pieces.b4 = {id: "b4", position: [6,8], color: "black", type: "bishop"}
    @pieces.q2 = {id: "q2", position: [5,8], color: "black", type: "queen"}
    @pieces.king2 = {id: "king2", position: [4,8], color: "black", type: "king"}


    save: (data) -> fs.writeFileSync('chessdata.txt', JSON.stringify(data))

  # move checking methods 
  ###
  samePos: (p1, p2) ->
    if p1[0] isnt p2[0] then return false
    if p1[1] isnt p2[1] then return false
    return true 
  ### 
  
  samePos: (p1, p2) ->
    (p1[0] is p2[0]) and (p1[1] is p2[1])
  
  ###
  findPiece: (pos) ->
    for key, value of chess.pieces
      if @samePos(pos, value.position) 
        console.log "found one!"
        return value
    return null
  ###
  findPiece: (pos) ->
    _.find chess.pieces, (piece) -> chess.samePos(piece.position, pos)

  between: (a, b) ->
    if a is b or Math.abs(a-b) is 1 then return null 
    else if a > b then return [a-1..b+1]
    else return [a+1..b-1]


  #checks the move and kills the enemy if at position "place"
  # check to see if move was legal (correct direction, amount of spaces, no other pieces in the path)
  checkMove: (piece, place) ->
    fromx = piece.position[0]
    fromy = piece.position[1]
    tox = place[0]
    toy = place[1]
    if @samePos(piece.position, place)
      console.log("Same spot!")
      return false
    piece2 = @findPiece(place)
    if piece2? and (piece.color is piece2.color) 
      console.log("No sharing!")
      return false

    likeARook = ->
      #check if correct directions
      if fromx isnt tox and fromy isnt toy 
        return false
      #check if any pieces are in the way
      #check on x axis first
      if chess.between(fromx, tox)?
        for n in chess.between(fromx, tox)
          if chess.findPiece([n, fromy])? 
            console.log("Someone's in the way!")
            return false
      #check on y axis
      if chess.between(fromy, toy)?
        for n in chess.between(fromy, toy)
          if chess.findPiece([fromx, n])? 
            console.log("Someone's in the way!")
            return false
      return true 

    likeABishop = ->
      if Math.abs(fromx-tox) isnt Math.abs(fromy-toy) then return false
      if chess.between(fromx, tox)? and chess.between(fromy, toy)?
        i=0
        for x in chess.between(fromx, tox)
          if chess.findPiece([x, chess.between(fromy, toy)[i]])? 
            console.log("Someone's in the way!")
            return false
          i++
      return true

    switch(piece.type)
      when 'pawn' #aka 'mr special case'
        z = 0
        if piece.color is "white" then z=1 else z=-1
        #look for attack
        if piece2?
          if ((fromx+1 is tox) and (fromy+1*z is toy)) or ((fromx-1 is tox) and (fromy+1*z is toy))
            piece.firstMove = false
            return true
          else return false
        #good if just moving one ahead
        if (fromx is tox) and (fromy+1*z is toy) 
          piece.firstMove = false
          return true
        #if trying to move 2 ahead, it better be the first move
        if (fromx is tox) and (fromy+2*z is toy) and piece.firstMove
          piece.firstMove = false
          return true
        return false

      when 'rook' # aka 'the tester'
        return likeARook()

      when 'knight' # aka 'blissfully short'
        if (Math.abs(fromx-tox) is 1 and Math.abs(fromy-toy) is 2) or (Math.abs(fromx-tox) is 2 and Math.abs(fromy-toy) is 1) then return true
        return false

      when 'bishop' # aka 'oh dear lord there must be a better way, and there was'
        return likeABishop()

      when 'queen'
        return (likeARook() or likeABishop())

      when 'king'
        if ((Math.abs(fromx-tox)) is (0 or 1)) and ((Math.abs(fromy-toy)) is (0 or 1)) then return true
        else return false

      else
        console.log("That's not even a piece!") 
        return false

  move: (pieceID, place) ->
    if @checkMove(chess.pieces[pieceID], place) 
      console.log "move says: Legal move!"
      if victim = @findPiece(place)
        console.log "Its an attack!"
        if victim.type is 'king'
          @gameOver = true
          if victim.color is "white" then @winner = "black" else @winner = "white"
        delete chess.pieces[victim.id]
      chess.pieces[pieceID].position = place 
      return true
    else 
      console.log("move says: Illegal move!")
      return false
}

listProps = (object) ->
  string = ""
  for key, value of object
    string += "#{key}: #{value}, "
  string

module.exports = chess

#testing 
###
chess.setPieces()
console.log(chess.pieces)
chess.move(chess.pieces.king1, [4,7])
console.log(chess.pieces.king1)
###

###
# queen
move(pieces.queen, [4,7])
console.log(pieces.queen)
pieces.p4 = {id: "p4", position: [1,4], color: "black", type:"pawn"}
move(pieces.queen, [0,3])
console.log(pieces.queen)
###

###
# bishop1
move(pieces.b1, [6,4])
console.log(pieces.b1)
pieces.p4 = {id: "p4", position: [4,6], color: "black", type:"pawn"}
move(pieces.b1, [4,6])
console.log(pieces.b1)
console.log(pieces.p4)
###

###
# knight1
move(pieces.k1, [1,3])
console.log(pieces.k1)

move(pieces.k1, [3,2])
console.log(pieces.k1)
console.log(pieces.p3)
###
### p1
move(pieces.p1, [3,4])
console.log(pieces.p1)

move(pieces.p1, [1,5])
console.log(pieces.p1)

move(pieces.p1, [1,3])
console.log(pieces.p1)
###
###
# rooks
# example where rook1 travels from [1,1] to [2,1]
console.log("Rook 1 goes on a journey")
move(pieces.r1, [3,1])
console.log(pieces.r1)

# example where rook2 travels from [8,1] to [7,2]
console.log("Rook 2 goes on a journey")
move(pieces.r2, [7,1])
console.log(pieces.r2)
###

###
for key, value of pieces
  console.log("key: #{key}, value: #{value}, position: #{value.position}")
  if samePos([1,1], value.position) then console.log("Conflict!")
###


