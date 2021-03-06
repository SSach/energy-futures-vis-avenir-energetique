d3 = require 'd3'
_ = require 'lodash'

class chart
  #local variables
  defaults:
    size:  
      w: 200
      h: 300
    position:  
      x: 0
      y: 0
    data: []
    duration: 1000
    group: 0
    groupId: 'sChart' 

  constructor: (parent, op = {}) ->
    @options = _.extend {}, @defaults, op
    @_duration = @options.duration
    @parent(parent, @options.groupId)
    @_size = 
      w : @options.size.w
      h : @options.size.h
    @_position = 
      x : @options.position.x
      y : @options.position.y
    @data(@options.data)
    @resize()
    @redraw()

  #getters and setters (return chart object for chaining)
  parent: (prnt, groupClass) ->
    if arguments.length
      @_parent = if typeof prnt == 'string' or prnt instanceof String then d3.select(prnt) else prnt
      @_group = if !(d3.select("##{groupClass}").empty()) then d3.select("##{groupClass}") else @_parent.append('svg:g').attr(id: groupClass)
      this
    else
      @_parent.node()

  # Returns the size withOUT the margins
  size: (s) ->
    if !arguments.length
      return {
        w: @_size.w
        h: @_size.h
      }
    @_size = 
      w: s.w
      h: s.h
    @redraw()

  # Returns the position withOUT the marginss 
  position: (pos) ->
    if !arguments.length
      return {
        x: @_position.x
        y: @_position.y
      }
    @_position = 
      x: pos.x
      y: pos.y
    @redraw()

  data: (d, key) ->
    if !arguments.length
      return @_data
    @_data = d
    @_key = key
    @redraw()

  resize: ->
    @size(@size())
    @position(@position())
    @_group.attr
        transform: "translate(" + @_position.x + "," + @_position.y + ")"
    this

  # dummy redraw

  redraw: ->
    if @_size and @_position  
      @_group.selectAll('rect').remove()
      @_group.append('rect')
        .attr(
          x: @_position.x
          y: @_position.y
          width: @_size.w
          height: @_size.h
        )
    this

  this
  #each different type of chart and its related functions: will need draw method

module.exports = chart