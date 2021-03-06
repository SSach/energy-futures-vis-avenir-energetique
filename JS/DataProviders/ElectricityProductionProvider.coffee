d3 = require 'd3'
Constants = require '../Constants.coffee'
UnitTransformation = require '../unit-transformation.coffee'
Tr = require '../TranslationTable.coffee'

class ElectricityProductionProvider



  constructor: (loadedCallback) ->

    @data = null
    @loadedCallback = loadedCallback

    d3.csv "CSV/ElectricityGeneration_VIZ.csv", @csvMapping, @parseData
  




  csvMapping: (d) ->
    province: d.Area
    source: d.Source
    scenario: d.Case
    year: parseInt(d.Year)
    value: parseFloat(d.Data)

  parseData: (error, data) =>
    console.warn error if error?
    @data = data

    # Normalize some of the data in the CSV, to make life easier later
    # TODO: precompute some of these changes?

    for item in @data
      item.scenario = Constants.csvScenarioToScenarioNameMapping[item.scenario]

    for item in @data
      item.source = Constants.csvSourceToSourceNameMapping[item.source]

    for item in @data
      item.province = Constants.csvProvinceToProvinceCodeMapping[item.province]

    @data = @data.filter (item) ->
      item.source not in ['crudeOil', 'electricity']

    @dataByProvince = 
      'BC' : []
      'AB' : []
      'SK' : []
      'MB' : []
      'ON' :  []
      'QC' : []
      'NB' : []
      'NS' : []
      'NL' : []
      'PE' : []
      'YT' :  []
      'NT' :  []
      'NU' :  []
      'all' : []

    @dataBySource = 
      hydro: []
      solarWindGeothermal: []
      coal: []
      naturalGas: []
      bio: []
      nuclear: []
      oilProducts: []
      crudeOil: []
      electricity: []
      total: []

    @dataByScenario = 
      reference: []
      high: []
      low: []
      highLng: []
      noLng: []
      constrained: []

    @calculateTotalsForCanada()

    for item in @data
      @dataByScenario[item.scenario].push item
      @dataByProvince[item.province].push item
      @dataBySource[item.source].push item

    @loadedCallback()

    

  # We need certain totals for viz4 which aren't present in the data.
  # We compute them, and add them to the existing data in memory
  # NB: We are only calculating these totals for Total Generation, we are not calculating
  # them out for each power source!
  calculateTotalsForCanada: ->
    # We're only interested in total generation, not individual sources
    totalGenerationData = @data.filter (item) ->
      item.source == 'total'

    # Break data out by year and scenario
    totalGenerationByYearAndScenario = {}
    for year in Constants.years
      totalGenerationByYearAndScenario[year] = {}
      for scenario in Constants.scenarios
        totalGenerationByYearAndScenario[year][scenario] = []

    for item in totalGenerationData
      totalGenerationByYearAndScenario[item.year][item.scenario].push item

    # For each set of provincial/territorial data in each year and scenario, 
    # find the sum of their production, and add it to the raw data for the provider

    for scenario in Constants.scenarios
      for year in Constants.years
        sum = totalGenerationByYearAndScenario[year][scenario].reduce (sum, item) ->
          sum + item.value
        , 0

        @data.push
          province: 'all'
          source: 'total'
          scenario: scenario
          year: year
          value: sum



  # accessors note: this is never needed for viz 2!!
  dataForViz1: (viz1config) ->
    filteredProvinceData = {}    

    # Exclude data from provinces that aren't in the set
    for provinceName in Object.keys @dataByProvince
      if viz1config.provinces.includes provinceName
        filteredProvinceData[provinceName] = @dataByProvince[provinceName]

    # We aren't interested in breakdowns by source, only the totals and only the correct scenario
    for provinceName in Object.keys filteredProvinceData
      filteredProvinceData[provinceName] = filteredProvinceData[provinceName].filter (item) ->
        item.source == 'total' and item.scenario == viz1config.scenario

    # Finally, convert units
    return filteredProvinceData if viz1config.unit == 'gigawattHours'

    if viz1config.unit == 'kilobarrelEquivalents' or viz1config.unit == 'petajoules' 
      unitConvertedProvinceData = {}
      for province in Object.keys filteredProvinceData
        unitConvertedProvinceData[province] = []
        for item in filteredProvinceData[province]
          unitConvertedProvinceData[province].push 
            # TODO: This approach is pretty nasty, is there a better way?
            province: item.province
            sector: item.sector
            source: item.source
            scenario: item.scenario
            year: item.year
            value: item.value * UnitTransformation.transformUnits('gigawattHours', viz1config.unit)
      return unitConvertedProvinceData


  dataForViz3: (viz3config) ->
    filteredData = {} #this is filtered by the viewBy

    if viz3config.viewBy == 'province' 
      dataToUse = @dataByProvince
      singleSelectFilterName = 'provinces'
      stackedFilterName = 'sources'
      allValidNames = viz3config.sourcesInOrder
      nameField = 'source'
    else 
      dataToUse = @dataBySource
      singleSelectFilterName = 'sources'
      stackedFilterName = 'provinces'
      allValidNames = viz3config.provincesInOrder
      nameField = 'province'

    # When province/source is all/total, add in all of the provinces/sources
    # Otherwise only add the one province or source selected

    if viz3config[viz3config.viewBy] == 'all' or viz3config[viz3config.viewBy] == 'total'
      for name in Object.keys dataToUse
        if name != 'total' and name != 'all' #we should not include these since they are merely sums 
          filteredData[name] = dataToUse[name]
    else 
      filteredData[viz3config[viz3config.viewBy]] = dataToUse[viz3config[viz3config.viewBy]]

    # Include only the year and non zero value
    for name in Object.keys filteredData
      filteredData[name] = filteredData[name].filter (item) ->
        item.year == viz3config.year

    # Include only data for the current scenario
    for name in Object.keys filteredData
      filteredData[name] = filteredData[name].filter (item) ->
        item.scenario == viz3config.scenario

    # THIS IS JUST EXCLUDING CRUDE OIL AND TOTAL SINCE WE DONT HAVE IMAGES FOR IT
    for name in Object.keys filteredData
      filteredData[name] = filteredData[name].filter (item) ->
        item[nameField] in allValidNames and item.value != 0

    #So um units are not really used?
    if viz3config.unit == 'kilobarrelEquivalents' or viz3config.unit == 'petajoules' 
      unitConvertedData = {}
      for name in Object.keys filteredData
        unitConvertedData[name] = []
        for item in filteredData[name]
          unitConvertedData[name].push 
            # TODO: This approach is pretty nasty, is there a better way?
            province: item.province
            sector: item.sector
            source: item.source
            scenario: item.scenario
            year: item.year
            value: item.value * UnitTransformation.transformUnits('gigawattHours', viz3config.unit)
      filteredData = unitConvertedData

    childrenKeys = {}
    bubbleObj = 
      name: "Total"
      children: []
      viewBy: viz3config.viewBy
    for source, array of filteredData
      for item in array
        if childrenKeys[source] == undefined 
          childrenKeys[source] = bubbleObj.children.length #Save the index for easy access later
          bubbleObj.children.push(
            name: source
            children: []
          )
        bubbleObj.children[childrenKeys[source]].children.push(
          name: if viz3config.viewBy == 'province' then "#{Tr.sourceSelector.sources[item[nameField]][app.language]} #{source}" else "#{item[nameField]} #{Tr.sourceSelector.sources[source][app.language]}"  #for titles
          id: "#{item[nameField]}#{source}" #to distinguish
          source: item[nameField]
          size: if viz3config[stackedFilterName].includes item[nameField] then item.value else 0.001
        )
    bubbleObj





  dataForViz4: (viz4config) ->
    filteredScenarioData = {}    

    # Exclude data from scenarios that aren't in the set
    for scenarioName in Object.keys @dataByScenario
      if viz4config.scenarios.includes scenarioName
        filteredScenarioData[scenarioName] = @dataByScenario[scenarioName]

    # We aren't interested in breakdowns by source, only the totals
    # TODO: Since this will always be the case for viz4, cache the data with this filter applied?
    for scenarioName in Object.keys filteredScenarioData
      filteredScenarioData[scenarioName] = filteredScenarioData[scenarioName].filter (item) ->
        item.source == 'total'

    # Include only data for the current province
    for scenarioName in Object.keys filteredScenarioData
      filteredScenarioData[scenarioName] = filteredScenarioData[scenarioName].filter (item) ->
        item.province == viz4config.province


    # Finally, convert units
    return filteredScenarioData if viz4config.unit == 'gigawattHours'

    if viz4config.unit == 'kilobarrelEquivalents' or viz4config.unit == 'petajoules' 
      unitConvertedScenarioData = {}
      for scenario in Object.keys filteredScenarioData
        unitConvertedScenarioData[scenario] = []
        for item in filteredScenarioData[scenario]
          unitConvertedScenarioData[scenario].push 
            # TODO: This approach is pretty nasty, is there a better way?
            province: item.province
            sector: item.sector
            source: item.source
            scenario: item.scenario
            year: item.year
            value: item.value * UnitTransformation.transformUnits('gigawattHours', viz4config.unit)
      return unitConvertedScenarioData

    # TODO: if we get to here something has gone horribly wrong, and we should do something else
    console.warn 'something has gone wrong'



module.exports = ElectricityProductionProvider