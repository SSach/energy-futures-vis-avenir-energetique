_ = require 'lodash'
Constants = require '../Constants.coffee'
Tr = require '../TranslationTable.coffee'

class Visualization1Configuration
  defaultOptions: 
    mainSelection: 'energyDemand'
    unit: 'petajoules'
    scenario: 'reference'
    provinces: [
      'AB'
      'BC'
      'MB'
      'NB' 
      'NL'
      'NS' 
      'NT' 
      'NU'
      'ON'
      'PE'
      'QC'
      'SK'
      'YT' 
    ]
    provincesInOrder: [
      'AB'
      'BC'
      'MB'
      'NB' 
      'NL'
      'NS' 
      'NT' 
      'NU'
      'ON'
      'PE'
      'QC'
      'SK'
      'YT' 
    ]

  constructor: (options) ->
    @options = _.extend {}, @defaultOptions, options

    # mainSelection, one of energyDemand, oilProduction, electricityGeneration, or gasProduction
    @setMainSelection @options.mainSelection

    # unit, one of:
    # petajoules
    # kilobarrelEquivalents - kilobarrels of oil equivalent per day, kBOE/day 
    # gigawattHours - GWh
    # thousandCubicMetres - thousand cubic metres per day, m^3/day (oil)
    # millionCubicMetres - million cubic metres per day, m^3/day (gas)
    # kilobarrels - kilobarrels of oil per day, kB/day
    # cubicFeet - million cubic feet per day, Mcf/day
    @setUnit @options.unit

    # one of: reference, constrained, high, low, highLng, noLng
    @setScenario @options.scenario
    
    # provinces, array
    # can include any of: BC AB SK MB ON QC NB NS NL PE YT NT NU all
    @provinces = []
    for province in @options.provinces
      @addProvince province

    # Used to manage the order of the provinces in a reorderable menu
    @provincesInOrder = @defaultOptions.provincesInOrder


  # Setters

  setMainSelection: (selection) ->
    if Constants.mainSelections.includes selection
      @mainSelection = selection
      if @mainSelection == 'electricityGeneration' 
        #we want this to be the default unit when changing to electricity generation
        @unit = 'gigawattHours'
    else
      @mainSelection = 'energyDemand'

    # When the selection changes, the set of allowable units and scenarios change
    # Calling setUnit and setScenario validates the current choices
    @setUnit @unit
    @setScenario @scenario

  setUnit: (unit) ->
    allowableUnits = []
    switch @mainSelection
      when 'energyDemand'
        allowableUnits = ['petajoules', 'kilobarrelEquivalents']
      when 'electricityGeneration'
        allowableUnits = ['gigawattHours', 'petajoules', 'kilobarrelEquivalents']
      when 'oilProduction'
        allowableUnits = ['kilobarrels', 'thousandCubicMetres']
      when 'gasProduction'
        allowableUnits = ['cubicFeet', 'millionCubicMetres']
    if allowableUnits.includes unit
      @unit = unit
    else
      @unit = allowableUnits[0]
    @updateRouter()

  setScenario: (scenario) ->
    allowableScenarios = []
    switch @mainSelection
      when 'energyDemand', 'electricityGeneration'
        allowableScenarios = Constants.scenarios
      when 'oilProduction'
        allowableScenarios = ['reference', 'constrained', 'high', 'low']
      when 'gasProduction'
        allowableScenarios = ['reference', 'high', 'low', 'highLng', 'noLng']
    if allowableScenarios.includes scenario
      @scenario = scenario
    else
      @scenario = allowableScenarios[0]
    @updateRouter()

  addProvince: (province) ->
    return unless Constants.provinces.includes province
    @provinces.push province unless @provinces.includes province
    @updateRouter()

  removeProvince: (province) -> 
    @provinces = @provinces.filter (p) -> p != province
    @updateRouter()

  flipProvince: (province) ->
    return unless Constants.provinces.includes province
    if @provinces.includes province 
      @provinces = @provinces.filter (p) -> p != province
    else 
      @provinces.push province
    @updateRouter()

  resetProvinces: (selectAll) ->
    if selectAll
      @provinces = [
        'BC'
        'AB'
        'SK' 
        'MB'
        'ON' 
        'QC' 
        'NB' 
        'NS' 
        'NL' 
        'PE' 
        'YT' 
        'NT' 
        'NU'
      ]
    else
      @provinces = []
    @updateRouter()

  setProvincesInOrder: (provincesInOrder) ->
    # NB: We aren't currently tracking provinces in order in the URL bar
    @provincesInOrder = provincesInOrder

  # Router integration

  routerParams: ->
    page: 'viz1'
    mainSelection: @mainSelection
    unit: @unit
    scenario: @scenario
    provinces: @provinces
    
  updateRouter: ->
    return unless app? and app.router?
    window.app.router.navigate @routerParams()


  # Description for PNG export
  imageExportDescription: ->

    mainSelectionText = switch @mainSelection
      when 'energyDemand'
        Tr.mainSelector.totalDemandButton[app.language]
      when 'electricityGeneration'
        Tr.mainSelector.electricityGenerationButton/[app.language]
      when 'oilProduction'
        Tr.mainSelector.oilProductionButton[app.language]
      when 'gasProduction'
        Tr.mainSelector.gasProductionButton[app.language]

    unitText = switch @unit
      when 'petajoules'
        Tr.unitSelector.petajoulesButton[app.language]
      when 'kilobarrelEquivalents'
        Tr.unitSelector.kilobarrelEquivalentsButton[app.language]
      when 'gigawattHours'
        Tr.unitSelector.gigawattHourButton[app.language]
      when 'thousandCubicMetres'
        Tr.unitSelector.thousandCubicMetresButton[app.language]
      when 'millionCubicMetres'
        Tr.unitSelector.millionCubicMetresButton[app.language]
      when 'kilobarrels'
        Tr.unitSelector.kilobarrelsButton[app.language]
      when 'cubicFeet'
        Tr.unitSelector.cubicFeetButton[app.language]

    scenarioText = switch @scenario
      when 'reference'
        Tr.scenarioSelector.referenceButton[app.language]
      when 'constrained'
        Tr.scenarioSelector.constrainedButton[app.language]
      when 'high'
        Tr.scenarioSelector.highPriceButton[app.language]
      when 'low'
        Tr.scenarioSelector.lowPriceButton[app.language]
      when 'highLng'
        Tr.scenarioSelector.highLngButton[app.language]
      when 'noLng'
        Tr.scenarioSelector.noLngButton[app.language]

    description = ''
    description += "#{mainSelectionText} - "
    description += "#{Tr.imageExportText.unit[app.language]}: #{unitText} - "
    description += "#{Tr.imageExportText.scenario[app.language]}: #{scenarioText}"

    description





module.exports = Visualization1Configuration